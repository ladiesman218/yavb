import Vapor
import Leaf

struct PublicFEController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let routes = routes.grouped(User.sessionAuthenticator())
        routes.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> View {
        let userDTO = try? req.auth.require(User.self).dto
        var js: String? = nil
        // If query item named "login" with the value of 1 is in url, then pop the loginModal. This kinds of url should be redirected from protected routes, when a session is no longer valid, so the expired = true in js will add an alert telling users why they've been taken out of protected end points.
        if let a: Int = req.query["login"], a == 1 {
            js = """
popLoginModal(expired = true);
"""
        }
        return try await Self.renderHome(req, js: js, userDTO: userDTO)
    }
    
    static func renderHome(_ req: Request, title: String? = nil, js: String? = nil, jwt: String? = nil, userDTO: User.DTO? = nil) async throws -> View {
        let posts = try await PublicBlogController().getRecent(req)
        let context = PublicContext(title: title ?? "Welcome to \(siteName)", posts: posts, script: js, jwt: jwt, userDTO: userDTO)
        
        return try await req.view.render("main", context)
    }
}
