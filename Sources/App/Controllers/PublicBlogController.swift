import Vapor
import Fluent

struct PublicBlogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let blogRoute = routes.grouped("api", "blog")
        blogRoute.get(use: getRecent)
    }
    
    func getRecent(_ req: Request) async throws -> [BlogPost.DetailDTO] {
        let posts = try await BlogPost.query(on: req.db).group(.and, { group in
            group.filter(\.$status == .published)
            group.filter(\.$type == .post)
        }).sort(\.$updatedAt, .descending).with(\.$tags).with(\.$author).with(\.$comments).paginate(for: req)
        let dtos = try posts.items.map { try $0.detailDTO }
        
        return dtos
    }
    
    func getPost(_ req: Request) async throws -> BlogPost.DetailDTO {
        guard let id = req.parameters.get("id", as: BlogPost.IDValue.self) else {
            throw Abort(.badRequest)
        }
        guard let post = try await BlogPost.query(on: req.db).filter(\.$id == id).filter(\.$status == .published).with(\.$author).with(\.$tags).with(\.$comments).first() else {
            throw Abort(.notFound)
        }
        return try post.detailDTO
    }
}
