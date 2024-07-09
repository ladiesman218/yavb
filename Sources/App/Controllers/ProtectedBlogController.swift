import Vapor
import Fluent

struct ProtectedBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let protectedRoute = routes.grouped(User.sessionAuthenticator(), User.credentialsAuthenticator(), User.guardMiddleware()).grouped("api", "blog")
        protectedRoute.post("create", use: add)
        protectedRoute.get("getall", use: getByUpdateTime)
        protectedRoute.post("delete", ":id", use: remove)
        protectedRoute.post("update", ":id", use: update)
    }
    
    func add(_ req: Request) async throws -> HTTPStatus {
        let userID = try req.auth.require(User.self).requireID()
        let input = try req.content.decode(BlogPost.CreateInput.self)
        let type: BlogPost.PostType
        if let typeString = input.type {
            guard let t = BlogPost.PostType.init(rawValue: typeString) else {
                throw Abort(.badRequest, reason: "Post type Invalid")
            }
            type = t
        } else {
            type = BlogPost.PostType.post
        }
        let blog = App.BlogPost(title: input.title, excerpt: input.excerpt ?? "", content: input.content, authorID: userID, type: type, isPublished: input.isPublished ?? true)
        try await blog.save(on: req.db)
        
        guard let tagNames = input.tags else { return .created }
        
        do {
            try await Self.attach(tagNames: tagNames, for: blog, db: req.db)
        } catch {
            throw Abort(.internalServerError, reason: "Post saved, but attach tags failed: \(error)")
        }
        
        return .created
    }
    
    func getByUpdateTime(_ req: Request) async throws -> [BlogPost.DTO] {
        let posts = try await BlogPost.query(on: req.db).sort(\.$updatedAt).with(\.$author).with(\.$tags).paginate(for: req).map { try $0.dto }
        return posts.items
    }
    
    func remove(_ req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        
        guard let post = try await BlogPost.find(id, on: req.db) else { throw Abort(.notFound) }
        try await post.delete(on: req.db)
        return .ok
    }
    
    func update(_ req: Request) async throws -> HTTPStatus {
        guard let input = try? req.content.decode(BlogPost.UpdateInput.self),
              let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        guard let post = try await BlogPost.find(id, on: req.db) else { throw Abort(.notFound, reason: "Post doesn't exist") }
        if let title = input.title { post.title = title }
        if let excerpt = input.excerpt { post.excerpt = excerpt }
        if let content = input.content { post.content = content }
        if let typeString = input.type {
            guard let t = BlogPost.PostType.init(rawValue: typeString) else {
                throw Abort(.badRequest, reason: "Post type Invalid")
            }
            post.type = t
        }
        if let isPublished = input.isPublished { post.isPublished = isPublished }
        
        if let tagNames = input.tags {
            try await Self.attach(tagNames: tagNames, for: post, db: req.db)
        }
        
        try await post.save(on: req.db)
        return .ok
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
