import Vapor

struct SessionAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        
        var response = try await next.respond(to: request)
        // Check for requests that have an session cookie first.
        if let sessionCookie = request.cookies[sessionCookieName] {
            // If yes, check against db that the "data" column is not empty.
            if request.session.data.snapshot.isEmpty {
                // session.destory() removes session record from db, also removes cookie when front end receives the response.
                request.session.destroy()
                response.headers.replaceOrAdd(name: "session-expired", value: "true")
            }
        }
        return response
    }
}
