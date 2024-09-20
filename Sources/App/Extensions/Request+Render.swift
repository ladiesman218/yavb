import Vapor

struct GlobalContext<T: Renderable >: Encodable {
    let pageData: T
    let siteName: String
    var js: String?
    let loggedInUser: User.DTO?
    let jwt: String?
}

extension Request {
    func render<Context: Renderable>(_ template: String, _ context: Context, js: String? = nil) async throws -> View {
        let loggedInUser = try self.auth.get(User.self)?.dto
        let jwt = self.parameters.get("jwt")
        
        let gobalContext = GlobalContext(
            pageData: context,
            siteName: self.application.configuration.siteName,
            js: js,
            loggedInUser: loggedInUser,
            jwt: jwt
        )
        return try await self.view.render(template, gobalContext)
    }
}
