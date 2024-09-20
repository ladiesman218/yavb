import Vapor

extension Request {
    var host: String {
        get throws {
            guard let host = self.headers.first(name: .host) else {
                throw Abort(.internalServerError, reason: "Can not get host from request")
            }
            return host
        }
    }
}
