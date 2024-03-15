import Vapor
import Fluent

struct OpenAPIMiddleware: AsyncMiddleware {
    
    @TaskLocal
    static var request: Request?
    
    func respond(to request: Request, chainingTo responder: AsyncResponder) async throws -> Response {
        try await OpenAPIMiddleware.$request.withValue(request) {
            
            try await responder.respond(to: request)
        }
    }
}

extension APIProtocol {
    var request: Request { OpenAPIMiddleware.request! }
    var db: Database { request.db }
    var logger: Logger { request.logger }
    var client: Client { request.client }
}
