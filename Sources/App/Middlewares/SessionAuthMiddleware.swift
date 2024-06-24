import Vapor

/// Checks if a request has a session first, if yes, check if the session has expired. If also yes, the middleware destroys the session from db, also removes cookie when frontend receives the response automatically. This should only be used for unprotected endpoints, so that front end can remove cookies automatically.
struct SessionAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        
        if request.cookies[sessionCookieName] != nil {
            // If yes, check against db that the "data" column is not empty, this also works when the entire record is missing.
            if request.session.data.snapshot.isEmpty {
                // session.destory() removes session record from db, also removes cookie when frontend receives the response.
                request.session.destroy()
            }
        }
        
        return try await next.respond(to: request)
    }
}
