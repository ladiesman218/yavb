import Vapor
import Leaf

struct PublicFEController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let routes = routes.grouped(User.sessionAuthenticator())
        routes.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> View {
        let userDTO = try? req.auth.require(User.self).dto
        return try await Self.renderHome(req, userDTO: userDTO)
    }
    
    static func renderHome(_ req: Request, title: String? = nil, js: String? = nil, jwt: String? = nil, userDTO: User.DTO? = nil) async throws -> View {
        let posts = try await PublicBlogController().getRecent(req)
        let context = PublicContext(title: title ?? "Welcome to \(siteName)", posts: posts, script: js, jwt: jwt, userDTO: userDTO)
        
        return try await req.view.render("main", context)
    }
}
