import Vapor

struct FEProtectedController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let protected = routes.grouped(User.sessionAuthenticator(), User.guardMiddleware()).grouped("auth")
        protected.get("me", use: test)
    }
    
    func test(_ req: Request) async throws -> String {
        return "Hello"
    }
}
