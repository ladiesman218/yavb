import Vapor


struct FEManageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protectedRoute = routes.grouped("manage").grouped(User.sessionAuthenticator(), User.redirectMiddleware(path: "/auth/login"), User.guardMiddleware())
        protectedRoute.get(use: manageHome)
    }
    
    func manageHome(_ req: Request) async throws -> Response {
        let _ = try req.auth.require(User.self)
        
        return try await req.view.render("/Manage/main", ["sitename": "YAVB"]).encodeResponse(for: req)
    }
}
