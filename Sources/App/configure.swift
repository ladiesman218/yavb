import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.http.server.configuration.port = 8082
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME")!,
        password: Environment.get("DATABASE_PASSWORD")!,
        database: (app.environment == .testing) ? "yavb_testing" : Environment.get("DATABASE_NAME"),
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    // Config middlewares
    app.middleware = .init()    // Avoid use default middlewares, currently they are Vapor.RouteLoggingMiddleware, Vapor.ErrorMiddleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(OpenAPIMiddleware(), at: .end)
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(MyRouteLoggingMiddleware())
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    
    // Add migrations
    app.migrations.add(CreateUsers())
//    try app.autoRevert().wait()
    try app.autoMigrate().wait()
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
//    let recipient = try! Message.Recipient(name: "Test", contactInfo: "duncej@gmail.com")
//    let mail = try! Message(to: [recipient], placeHolders: ["test"], template: "this is a \(Message.placeHolder) from yavb", subject: "Hi there")
//    mail.send(client: app.client)
}
