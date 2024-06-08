import Vapor

struct FrontendController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get(use: getHome)
    }
    
    func getHome(_ req: Request) async throws -> View {
        try await req.view.render("main")
    }
}
