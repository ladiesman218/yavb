import Vapor
import Fluent

struct PublicBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let blogRoute = routes.grouped("api", "blog")
        blogRoute.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> [BlogPost.DTO] {
        let posts = try await BlogPost.query(on: req.db).group(.and, { group in
            group.filter(\.$isPublished == true)
            group.filter(\.$type == .post)
        }).sort(\.$updatedAt, .descending).with(\.$tags).with(\.$author).paginate(for: req)
        let dtos = try posts.items.map { try $0.dto }
        
        return dtos
    }
    
    func getPost(_ req: Request) async throws -> BlogPost.DTO {
        guard let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        guard let post = try await BlogPost.query(on: req.db).filter(\.$id == id).with(\.$author).with(\.$tags).first() else {
            throw Abort(.notFound)
        }
        return try post.dto
    }
}
