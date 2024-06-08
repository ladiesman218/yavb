import Vapor

struct ProtectedBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
//        let protectedRoute = routes.grouped(UserToken.authenticator(), User.guardMiddleware()).grouped("api", "auth")
//        protectedRoute.get("me", use: test)
    }
    
    func test(_ req: Request) async throws -> String {
        return "hello"
    }
}
