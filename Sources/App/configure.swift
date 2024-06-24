import FluentPostgresDriver
import Fluent
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.http.server.configuration.port = 8082
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME")!,
        password: Environment.get("DATABASE_PASSWORD")!,
        database: Environment.get("DATABASE_NAME")!,
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    app.fluent.pagination.pageSizeLimit = 50
    // The session driver should be configured before adding app.sessions.middleware to your application.
    app.sessions.configuration = .init(cookieName: sessionCookieName, cookieFactory: { sessionID in
#warning("TODO: add queue job to delete session by id when after one month of its creation")
        return .init(string: sessionID.string,
                     // expires and maxAge are essentially the same thing, for supporting different browsers. Set to 30 minutes, this will be updated upon each following request automatically(meaning following requests will extend a new 30 mins expiration time). This only returned in response cookies, and can be manually changed on client side, server has no way to track how long a sesion hasn't been activated unless each request updates(writes) db.
                     expires: Date(
                        timeIntervalSinceNow: 60 * 30
                     ),
//                     maxAge: 60 * 30,
                     maxAge: 86400 * 7,
                     domain: nil,
                     path: "/",
                     // isSecure requires https.
                     isSecure: (app.environment == .production) ? true : false,
                     // isHTTPOnly prevent cookies be accessed by js.
                     isHTTPOnly: true,
                     sameSite: .lax
        )
    })
    app.sessions.use(.fluent)
    
    // Config middlewares
    app.middleware = .init()    // Avoid use default middlewares, currently they are Vapor.RouteLoggingMiddleware, Vapor.ErrorMiddleware
    app.middleware.use(MyRouteLoggingMiddleware(logLevel: app.environment == .production ? .info : .warning))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(app.sessions.middleware)
    // Cusomized middleware to check if the session cookie has expired. If yes, removes record from db and frontend.
    app.middleware.use(SessionAuthMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Use sessions middleware globally, but only config to use sessionAuthenticator() on frontend routes later.
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    
    let jwtSecret = Environment.get("JWT_SECRET") ?? "secret"
    await app.jwt.keys.add(hmac: .init(from: jwtSecret), digestAlgorithm: .sha256)
    
    // Add migrations
    app.migrations.add(CreateUsers())
    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateOTPs())
    app.migrations.add(CreateBlogPosts())
    app.migrations.add(CreateTags())
    app.migrations.add(CreateBlogTagPivot())
//    try await app.autoRevert()
    try await app.autoMigrate()
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}
