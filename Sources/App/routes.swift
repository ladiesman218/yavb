import Fluent
import Vapor
import OpenAPIVapor

func routes(_ app: Application) throws {
    // Create a Vapor OpenAPI Transport using your application.
    let transport = VaporTransport(routesBuilder: app)
    
    // Create an instance of your handler type that conforms the generated protocol
    // defining your service API.
    let apiHandler = AuthAPI()
    
    // Call the generated function on your implementation to add its request handlers to the app.
    try apiHandler.registerHandlers(on: transport, serverURL: Servers.server1())    // server1() is generated from openapi.yaml, first item of the `servers` array
}
