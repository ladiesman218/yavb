import Vapor


struct FEManageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let redirectMiddleware = User.redirectMiddleware { req -> String in
            return "/?login=1&next=\(req.url.path)"
        }
        let protectedRoute = routes.grouped("manage").grouped(User.sessionAuthenticator(), redirectMiddleware, User.guardMiddleware())
        protectedRoute.get(use: manageHome)
    }
    
    func manageHome(_ req: Request) async throws -> Response {
        let _ = try req.auth.require(User.self)
        let posts = try await ProtectedBlogController().getByUpdateTime(req)
        let context = ManageContext(posts: posts)
        return try await req.render("/Manage/main", context).encodeResponse(for: req)
    }
}
