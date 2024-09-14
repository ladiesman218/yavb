import Vapor
import Fluent
import SQLKit

struct FEManageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let redirectMiddleware = User.redirectMiddleware { req -> String in
            return "/?login=1&next=\(req.url.path)"
        }
        let protectedRoute = routes.grouped("manage").grouped(User.sessionAuthenticator(), redirectMiddleware, User.guardMiddleware())
        protectedRoute.get(use: manageHome)
        protectedRoute.get("post", ":id", use: editPost)
        protectedRoute.get("post", use: addPost)
        
    }
    
    func manageHome(_ req: Request) async throws -> View {
        
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        async let posts = ProtectedBlogController().getPosts(req)

        let authorFilter: String = User.Role.allCases.filter {
            $0.authorizations.rawValue < user.role.authorizations.rawValue
        }.reduce(into: "", { partialResult, role in
            partialResult += "OR role = '\(role)' "
        })
        
        let allCasesSQLString = String(
            BlogPost.Status.allCases.reduce(into: "") { partialResult, status in
                partialResult += "COALESCE(SUM(CASE WHEN \(BlogPost.schema).\(BlogPost.FieldKeys.status) = '\(status)' THEN 1 ELSE 0 END), 0) AS \"\(status)\",\n"
            }.dropLast(2) // Remove extra trailing comma and \n
        )
        
        let sqlString = """
        SELECT
        \(allCasesSQLString)
        FROM \(BlogPost.schema)
        JOIN \(User.schema) ON \(BlogPost.schema).\(BlogPost.FieldKeys.authorID) = \(User.schema).id
        WHERE \(User.schema).id = '\(userID)'
        \(authorFilter)
        """
        
        let db = req.db as! any SQLDatabase
        guard let result = try await db.raw(SQLQueryString(sqlString)).first(decoding: StatusPostsCount.self) else { throw Abort(.internalServerError) }
        
        let context = try await ManagePostsListContext(statusPostsCount: result, basicCtx: .init(title: "Manage Posts"), posts: posts)
        let response = try await req.render("/Manage/post list", context)
        return response
    }
    
    func editPost(_ req: Request) async throws -> View {
        let post = try await ProtectedBlogController().getPostByID(req)
        let context = ManagePostContext(basicCtx: .init(title: "Edit Post"), post: post)
        let response = try await req.render("/Manage/edit post", context)
        return response
    }
    
    func addPost(_ req: Request) async throws -> View {
        let context = ManagePostContext(basicCtx: .init(title: "Add New Post"), post: nil)
        let response = try await req.render("/Manage/edit post", context)
        return response
    }
}
