import Vapor
import Fluent

struct PublicBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let blogRoute = routes.grouped("blog")
        blogRoute.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> [BlogPost.DTO] {
        let posts = try await BlogPost.query(on: req.db).filter(\.$isPublished == true).sort(\.$updatedAt, .descending).with(\.$tags).with(\.$author).paginate(for: req)
        let dtos = try posts.items.map { try $0.dto }
        
        return dtos
    }
}
