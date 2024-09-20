import Vapor
import Leaf

struct PublicFEController: RouteCollection {
    static func renderHome(_ req: Request, js: String? = nil) async throws -> View {
        let posts = try await PublicBlogController().getRecent(req)
        let pageData = PublicPostListCtx(basicCtx: .init(title: "Welecome to \(req.application.configuration.siteName)", description: "This is a sample description for the site"), js: js, posts: posts)
        return try await req.render("main", pageData, js: js)
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let routes = routes.grouped(User.sessionAuthenticator())
        routes.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> View {
        var js: String? = nil
        // If query item named "login" with the value of 1 is in url, then pop the loginModal. This kinds of url should be redirected from protected routes when a session is no longer valid, so the expired = true in js will add an alert telling users why they've been taken out of protected end points.
        if let a: Int = req.query["login"] {
            if a == 1 {
                js = "popLoginModal(expired = true);"
            } else if a == 2 {
                js = "popLoginModal(expired = false);"
            }
        }
        return try await Self.renderHome(req, js: js)
    }
    
    func getPost(_ req: Request) async throws -> View {
        let post = try await PublicBlogController().getPost(req)
        let pageData = PublicPostDetailCtx(basicCtx: .init(title: post.title, description: post.excerpt), post: post)
        return try await req.render("main", pageData)
    }
}
