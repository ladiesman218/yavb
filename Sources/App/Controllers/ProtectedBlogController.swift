import Vapor
import Fluent
import SQLKit

enum PostsOrder: String {
    case updated_at, title, comment_count
    func queryString(req: Request) throws -> String {
        let order: String = req.query[at: "order"] ?? "desc"
        guard order == "desc" || order == "asc" else { throw Abort(.badRequest, reason: "Invalid order parameter") }
        switch self {
            case .updated_at:
                return "ORDER BY \(BlogPost.FieldKeys.updatedAt.description) \(order)\n"
            case .title:
                return "ORDER BY \(BlogPost.FieldKeys.title.description) \(order)\n"
            case .comment_count:
                return "ORDER BY COALESCE(CommentCounts.comment_count, 0) \(order), updated_at \(order)\n"
        }
    }
}

struct ProtectedBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let protectedRoute = routes.grouped(User.sessionAuthenticator(), User.credentialsAuthenticator(), User.guardMiddleware()).grouped("api", "blog")
        protectedRoute.post("create", use: add)
        protectedRoute.get("getall", use: getPosts)
        protectedRoute.post("delete", ":id", use: remove)
        protectedRoute.post("update", ":id", use: update)
        protectedRoute.get(":id", use: getPostByID)
        protectedRoute.get("asdf", use: getPostByID)
    }
    
    func add(_ req: Request) async throws -> HTTPStatus {
        let blog = try BlogPost(from: req)
        try await blog.save(on: req.db)
        
        if let tagNames = try? req.content.get([String].self, at: "tags") {
            do {
                try await Self.attach(tagNames: tagNames, for: blog, db: req.db)
            } catch {
                throw Abort(.internalServerError, reason: "Post saved, but attach tags failed: \(error)")
            }
        }
        
        return .created
    }
    
    /// Supports filter by status(published, draft, pendingReview, rejected, all), author and tag. ordered_by title, updated_at, comment_count
    func getPosts(_ req: Request) async throws -> Page<BlogPost.ListDTO> {
        // Get ordered_by value, default to last update time
        let orderedByValue: String = req.query[at: "ordered_by"] ?? BlogPost.FieldKeys.updatedAt.description
        
        // Validate postsOrder value is legal
        guard let orderedBy = PostsOrder.init(rawValue: orderedByValue) else {
            throw Abort(.badRequest, reason: "Invalid order parameter")
        }
        
        let user = try req.auth.require(User.self)
        let lowerAuths = User.Role.allCases.filter { $0.authorizations.rawValue < user.role.authorizations.rawValue }
        
        // Add author filter.
        let authorFilter: String
        // If a query parameter exists, only search posts authored by that username
        let authorParam = try? req.query.get(String.self, at: "author")
        switch authorParam {
            case nil:
                // If a parameter isn't given, search all posts authored by current logged in user, along with other authors whose authorizations are lower.
                let userID = try user.requireID()
                authorFilter = "WHERE id = '\(userID)'" + lowerAuths.reduce(into: "", { partialResult, role in
                    partialResult += " OR role = '\(role)'"
                })
            case user.username:
                // If the given username is the logged in user's username, only filter for author is the username itself.
                authorFilter = "WHERE username = '\(authorParam!)'"
            default:
                // When searching for a username that's not the logged in user's, make sure the queried user's auth is lower than current logged in user.
                let roleString = lowerAuths.map { " role = '\($0)' " }.joined(separator: "OR")
                authorFilter = "WHERE username = '\(authorParam!)'" + " AND (" + roleString + ")"
        }
        
        var sqlString = """
        SELECT blogposts.id,
        title,
        updated_at,
        COALESCE(comment_count, 0) AS comment_count,
        author_name,
        status,
        (SELECT STRING_AGG(tags.name, ', ')
        FROM tags
        JOIN blog_tag_pivot ON tags.id = blog_tag_pivot.tag_id
        WHERE blog_tag_pivot.blog_id = blogposts.id
        ) AS tags
        FROM blogposts
        JOIN (
        SELECT id, username AS author_name, role
        FROM users
        \(authorFilter)
        ) AS Author ON blogposts.author_id = Author.id
        LEFT JOIN (
        SELECT post_id, COUNT(*) AS comment_count
        FROM comments
        GROUP BY post_id
        ) AS CommentCounts ON blogposts.id = CommentCounts.post_id
        
        """
        // Both tags and status filters have to be put in the end of the entire sql query. Status should be filtered last since tags needs to use join. Whether the status filter should be added as a 'WHERE' or an 'AND' clause depends on if tags filter already exists.
        var trailingFilterExists = false
        
        // Add tags filter. This supports filter by multiple tags. But we need to convert user input into lowercased version first.
        let tagsFilter = try req.query.get([String].self, at: "tag").map { $0.lowercased() }
        if !tagsFilter.isEmpty {
            trailingFilterExists = true
            let count = tagsFilter.count
            let string = tagsFilter.reduce("") { partialResult, element in
                // When partialResult is empty, add nothing. When it has some string already, add a comma and a space first, then add the next element but wrap that element in a pair of single quote first.
                partialResult + (partialResult.isEmpty ? "" : ", ") + "'" + element + "'"
            }
            
            sqlString += """
JOIN blog_tag_pivot ON blogposts.id = blog_tag_pivot.blog_id
JOIN tags ON blog_tag_pivot.tag_id = tags.id
WHERE lower(tags.name) IN (\(string))
GROUP BY blogposts.id,
         title,
         updated_at,
         author_name,
         status,
         CommentCounts.comment_count
HAVING COUNT(DISTINCT tags.id) = \(count)

"""
        }
        
        // Add status filter.
        let statusFilter = try? req.query.get(String.self, at: "status")
        switch statusFilter {
                // If a query parameter is not provided, or it equals to 'all', don't add anything to the query
            case "all", nil:
                break
            case "published":
                sqlString +=  trailingFilterExists ? "AND " : "WHERE "
                sqlString += "status = 'published'\n"
            case "draft":
                sqlString +=  trailingFilterExists ? "AND " : "WHERE "
                sqlString += "status = 'draft'\n"
            case "pending_review":
                sqlString +=  trailingFilterExists ? "AND " : "WHERE "
                sqlString += "status = 'pendingReview'\n"
            case "rejected":
                sqlString +=  trailingFilterExists ? "AND " : "WHERE "
                sqlString += "status = 'rejected'\n"
            default:
                throw Abort(.badRequest, reason: "Invalid parameter for status filter")
        }
        
        let db = req.db as! any SQLDatabase
        
        // Add order parameter
        sqlString += try orderedBy.queryString(req: req)
        // Get paginate parameters
        let page = req.query[at: "page"] ?? 1
        let per = req.query[at: "per"] ?? req.db.pageSizeLimit ?? 20
        
        let result = try await db.raw(SQLQueryString(sqlString)).all()
        let items = try result.enumerated().filter { (offset: Int, element: any SQLRow) in
            ((page - 1) * per ... page * per - 1).contains(offset)
        }.map { _, element in
            try element.decode(model: BlogPost.ListDTO.self)
        }
        
        return .init(items: items, metadata: .init(page: page, per: per, total: result.count))
    }
    
    func remove(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        
        guard let post = try await BlogPost.find(id, on: req.db) else { throw Abort(.notFound) }
        guard try post.author.requireID() == user.id || user.role == .webmaster else {
            throw Abort(.unauthorized)
        }
        try await post.delete(on: req.db)
        return .ok
    }
    
    func update(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard user.activated else { throw Abort(.unauthorized, reason: "Un-verified email address") }
        guard let input = try? req.content.decode(BlogPost.UpdateInput.self),
              let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        // User has to be the author of the post, or have higher authorizations.
        guard let post = try await BlogPost.query(on: req.db).filter(\.$id == id).with(\.$author).first(),
              try user.requireID() == post.author.id || user.role.authorizations.rawValue > post.author.role.authorizations.rawValue
        else {
            throw Abort(.unauthorized)
        }
        
        if let title = input.title { post.title = title }
        if let excerpt = input.excerpt { post.excerpt = excerpt }
        if let content = input.content { post.content = content }
        if let type = input.type {
            guard type != .page || user.role == .webmaster else { throw Abort(.unauthorized) }
            post.type = type
        }
        if let inputStatus = input.status {
            switch inputStatus {
                case .draft:
                    post.status = inputStatus
                case .pendingReview:
                    if try user.requireID() != post.author.id {
                        guard post.status != .draft else { throw Abort(.badRequest, reason: "Author is still editing this post, you may ask the author to publish it if needed") }
                    }
                    post.status = inputStatus
                case .published:
                    if try user.requireID() != post.author.id {
                        guard post.status != .draft else { throw Abort(.badRequest, reason: "Author is still editing this post") }
                        post.status = inputStatus
                    } else {
                        // Here means the user is the author of the post. If previous status is either pendingReview or rejected, set it to pendingReview.
                        if post.status == .pendingReview || post.status == .rejected {
                            post.status = .pendingReview
                            break
                        }
                        // Here means the previous status is either draft or published.
                        post.status = (req.application.configuration.postsNeedReview && user.role.authorizations == .author) ? .pendingReview : .published
                    }
                case .rejected:
                    guard try user.requireID() != post.author.id && post.status != .draft else {
                        throw Abort(.unauthorized)
                    }
                    post.status = inputStatus
            }
        }
        
        try await post.save(on: req.db)
        
        if let tagNames = try? req.content.get([String].self, at: "tags") {
            do {
                try await Self.attach(tagNames: tagNames, for: post, db: req.db)
            } catch {
                throw Abort(.internalServerError, reason: "Post saved, but attach tags failed: \(error)")
            }
        }
        return .ok
    }
    
    func getPostByID(_ req: Request) async throws -> BlogPost.DetailDTO {
        guard let idString = req.parameters.get("id"), let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest)
        }
        let user = try req.auth.require(User.self)
        guard let post = try await BlogPost.query(on: req.db).filter(\.$id == id).with(\.$tags).with(\.$author).first() else {
            throw Abort(.notFound)
        }
        guard try user.requireID() == post.author.id || user.role.authorizations.rawValue > post.author.role.authorizations.rawValue else {
            throw Abort(.unauthorized)
        }
        
        return try post.detailDTO
    }
    
    @discardableResult
    static func attach(tagNames: [String], for post: BlogPost, db: Database) async throws -> HTTPStatus {
        try await post.$tags.load(on: db)
        try await db.transaction { db in
            try await post.$tags.detachAll(on: db)
            try await ProtectedTagController.add(tagNames: tagNames, database: db)
            let tags = try await Tag.query(on: db).filter(\Tag.$name ~~ tagNames).all()
            try await post.$tags.attach(tags, on: db)
        }
        return .ok
    }
    
}
