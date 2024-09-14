import Vapor

struct ProtectedCommentController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let protectedRoute = routes.grouped(User.sessionAuthenticator(), User.credentialsAuthenticator(), User.guardMiddleware()).grouped("api", "comment")
        protectedRoute.post("create", use: create)
    }
    
    func create(_ req: Request) async throws -> HTTPResponseStatus {
        let user = try req.auth.require(User.self)
        guard user.activated else {
            throw Abort(.forbidden, reason: "You need to activate your account")
        }
        return .created
    }
    
    func edit(_ req: Request) async throws -> HTTPResponseStatus {
        
        return .ok
    }
    
    func delete(_ req: Request) async throws -> HTTPResponseStatus {
        
        return .noContent
    }
    
    func getForPost(_ req: Request) async throws -> [Comment] {
        
        return []
    }
    
    func getAll(_ req: Request) async throws -> [Comment] {
        
        return []
    }
}
