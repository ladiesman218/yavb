import Vapor
import OpenAPIVapor
import OpenAPIRuntime

func routes(_ app: Application) throws {
    // Redirect /openapi to openapi.html, which serves the rendered documentation.
    app.get("openapi") { $0.redirect(to: "/openapi.html", redirectType: .permanent) }
    let myMiddlewares: [ServerMiddleware] = []
    // Create a Vapor OpenAPI Transport using your application.
    let transport = VaporTransport(routesBuilder: app)
    
    // Call the registerHandlers function on APIProtocol to add its request handlers to the app.
    try API().registerHandlers(on: transport, serverURL: Servers.server1(), middlewares: myMiddlewares)   // server1() is generated from openapi.yaml, first item of the `servers` array
}
