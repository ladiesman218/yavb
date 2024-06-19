import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: ProtectedBlogController())
    try app.register(collection: FrontendAuthController())
    try app.register(collection: PublicFEController())
    try app.register(collection: ProtectedTagController())
    try app.register(collection: PublicBlogController())
    try app.register(collection: FEManageController())
}
