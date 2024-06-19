import Vapor

struct PublicFEController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get(use: getRecent)
    }
    
//    func getHome(_ req: Request) async throws -> View {
//        try await req.view.render("main")
//    }
    func getRecent(_ req: Request) async throws -> View {
        try await Self.renderHome(req)
    }
    
    static func renderHome(_ req: Request, js: String? = nil) async throws -> View {
        let posts = try await PublicBlogController().getRecent(req)
        return try await req.view.render("main", MainContext(title: "Welcome to Yet Another Vapor Blog", posts: posts, script: js))
    }
}

extension PublicFEController {
    struct MainContext: Encodable {
        let title: String
        let posts: [BlogPost.DTO]
        var script: String? = nil
    }
}
