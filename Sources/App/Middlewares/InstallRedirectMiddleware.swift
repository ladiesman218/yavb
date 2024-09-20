import Vapor
import Fluent

struct InstallRedirectMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // if webmaster doesn't exist, and url path isn't prefixed with /install, redirect the request to /install. Otherwise respond to the original request.
        guard webmasterExists || request.url.path.hasPrefix("/install") else {
            return request.redirect(to: "/install")
        }
        return try await next.respond(to: request)
    }
}
