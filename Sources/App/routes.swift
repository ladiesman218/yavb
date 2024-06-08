import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: ProtectedBlogController())
    try app.register(collection: FrontendAuthController())
    try app.register(collection: FEProtectedController())
    try app.register(collection: FrontendController())
}
