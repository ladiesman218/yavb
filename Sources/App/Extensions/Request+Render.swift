import Vapor

extension Request {
    func render<Context: Encodable>(_ template: String, _ context: Context, js: String? = nil) async throws -> View {
        let loggedInUser = try self.auth.get(User.self)?.dto
        let jwt = self.parameters.get("jwt")
        let gobalContext = GlobalContext(
            pageData: context,
            loggedInUser: loggedInUser,
            jwt: jwt,
            script: js
        )
        return try await self.view.render(template, gobalContext)
    }
}

struct GlobalContext<T>: Encodable where T: Encodable {
    let pageData: T
    let loggedInUser: User.DTO?
    let jwt: String?
    let script: String?
    let siteName: String = App.siteName
    let shortName = App.shortName
}
