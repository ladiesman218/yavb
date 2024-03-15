import Vapor

public final class MyRouteLoggingMiddleware: Middleware {
    public let logLevel: Logger.Level
    
    public init(logLevel: Logger.Level = .info) {
        self.logLevel = logLevel
    }
    
    // Currently same as the default RouteLoggingMiddleware, will try to play around.
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        request.logger.log(level: self.logLevel, "\(request.method) \(request.url.path.removingPercentEncoding ?? request.url.path)")
        return next.respond(to: request)
    }
}
