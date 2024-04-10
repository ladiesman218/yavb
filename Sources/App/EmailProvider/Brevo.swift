import Vapor

enum Brevo {
    static func routeBrevo(_ app: Application) throws {
        app.post("api", "brevo", "send", "transactional") { req -> String in
            return "success"
        }
    }
}

