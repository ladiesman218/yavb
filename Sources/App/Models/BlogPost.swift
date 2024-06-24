import Vapor
import Fluent

final class BlogPost: Model, Content, @unchecked Sendable {
    
    static let schema = "blogposts"
    
    @ID() var id:  UUID?
    @Field(key: FieldKeys.title) var title: String
    @Field(key: FieldKeys.excerpt) var excerpt: String
    @Field(key: FieldKeys.content) var content: String
    @Parent(key: FieldKeys.authorID) var author: User
    @Enum(key: FieldKeys.type) var type: PostType
    @Field(key: FieldKeys.isPublished) var isPublished: Bool
    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date? 
    @Siblings(through: BlogTagPivot.self, from: \.$blog, to: \.$tag) var tags: [Tag]
    
    init() {}
    
    init(id: BlogPost.IDValue? = nil, title: String, excerpt: String, content: String, authorID: User.IDValue, type: PostType = .post, isPublished: Bool = true) {
        self.id = id
        self.title = title
        self.excerpt = excerpt
        self.content = content
        self.$author.id = authorID
        self.type = type
        self.isPublished = isPublished
    }
}

extension BlogPost {
    enum FieldKeys {
        static let title: FieldKey = .init(stringLiteral: "title")
        static let excerpt: FieldKey = .init(stringLiteral: "excerpt")
        static let content: FieldKey = .init(stringLiteral: "content")
        static let authorID: FieldKey = .init(stringLiteral: "author_id")
        static let type: FieldKey = .init(stringLiteral: "type") // Post or page
        static let isPublished: FieldKey = .init(stringLiteral: "published")
        static let createdAt: FieldKey = .init(stringLiteral: "create_at")
        static let updatedAt: FieldKey = .init(stringLiteral: "update_at")
    }
    
    enum PostType: String, Codable {
        case post
        case page
    }
    struct DTO: Content {
        let id: UUID
        let title: String
        let excerpt: String
        let content: String
        let auther: AuthorDTO
        let type: PostType
        let isPublished: Bool
        let createdAt: Date?
        let updatedAt: Date?
        let tags: [Tag]
    }
    
    // Less info than User.DTO
    struct AuthorDTO: Codable {
        let id: UUID
        let username: String
    }
    var dto: DTO {
        get throws {
            let id = try requireID()
            let authorDTO = AuthorDTO(id: try author.requireID(), username: author.username)
            return .init(id: id, title: title, excerpt: excerpt, content: content, auther: authorDTO, type: type, isPublished: isPublished, createdAt: createdAt, updatedAt: updatedAt, tags: tags)
        }
    }
    
    struct CreateInput: Content {
        let title: String
        let content: String
        let excerpt: String?
        let tags: [String]?
        let type: PostType.RawValue?
        let isPublished: Bool?
    }
    
    struct UpdateInput: Content {
        let title: String?
        let excerpt: String?
        let content: String?
        let tags: [String]?
        let type: PostType.RawValue?
        let isPublished: Bool?
    }
}
