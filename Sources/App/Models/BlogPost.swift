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
    @Enum(key: FieldKeys.status) var status: Status
    @Timestamp(key: FieldKeys.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.updatedAt, on: .update) var updatedAt: Date? 
    @Siblings(through: BlogTagPivot.self, from: \.$blog, to: \.$tag) var tags: [Tag]
    @Children(for: \Comment.$post) var comments: [Comment]
    
    init() {}
    
    init(id: BlogPost.IDValue? = nil, title: String, excerpt: String, content: String, authorID: User.IDValue, type: PostType = .post, status: Status) {
        self.id = id
        self.title = title
        self.excerpt = excerpt
        self.content = content
        self.$author.id = authorID
        self.type = type
        self.status = status
    }
    
    convenience init(from req: Request) throws {
        let user = try req.auth.require(User.self)
        guard user.activated else { throw Abort(.unauthorized, reason: "Un-verified email address") }
        guard user.role.authorizations.contains(.addPost) else { throw Abort(.unauthorized, reason: "Do not have authorization to add post") }
        let input = try req.content.decode(BlogPost.CreateInput.self)
        guard input.type != .page || user.role == .webmaster else { throw Abort(.unauthorized) }
        
        let status: Status
        switch input.status {
            case .rejected, .pendingReview:
                throw Abort(.badRequest, reason: "Available status for new post are: \(BlogPost.Status.draft) and \(BlogPost.Status.published)")
            case .published:
                status = (postsNeedReview && !user.role.authorizations.contains(.reviewPost)) ? .pendingReview : .published
            default:
                status = .draft
        }
        
        self.init(title: input.title, excerpt: input.excerpt ?? "", content: input.content, authorID: try user.requireID(), type: input.type ?? .post, status: status)
    }
}

extension BlogPost {
    enum Status: String, Codable, CaseIterable {
        // Indicates a post is in editing process. Both owner of the post, and any other users with higher level of authorizations than the owner can change a post to draft from any previous status.
        case draft
        // Indicates a post is waiting for higher level users' review to become published. When postsNeedReview is on, every time an author(those doesn't have .reviewPosts authorization) creates/updates a post of which status is not draft, should become pendingReview automatically. Any other user with higher level of management auth than the owner can change posts of which status is not draft, to pendingReview despite whether postsNeedReview is on/off.
        case pendingReview
        // Indicates a post can be viewed publicly. Normal author can change a post's status to published from any status other than rejected and pendingReview when postsNeedReview is off, if it's on, manually set status to pendingReview dispite previous status. Higher level of users can change a post to published from any status other than draft.
        case published
        // Indicates a post has gone through review process, but failed to meet the criteria to be published. Only users with higher level than the author of the post can change a post to rejected from any status other than draft.
        case rejected
    }
    
    enum FieldKeys {
        static let title: FieldKey = .init(stringLiteral: "title")
        static let excerpt: FieldKey = .init(stringLiteral: "excerpt")
        static let content: FieldKey = .init(stringLiteral: "content")
        static let authorID: FieldKey = .init(stringLiteral: "author_id")
        static let type: FieldKey = .init(stringLiteral: "type") // Post or page
        static let status: FieldKey = .init(stringLiteral: "status")
        static let createdAt: FieldKey = .init(stringLiteral: "created_at")
        static let updatedAt: FieldKey = .init(stringLiteral: "updated_at")
    }
    
    enum PostType: String, Codable {
        case post
        case page
    }
}

extension BlogPost {
    struct CreateInput: Content {
        let title: String
        let excerpt: String?
        let content: String
        let type: PostType?
        var status: Status
    }
    
    struct UpdateInput: Content {
        let title: String?
        let excerpt: String?
        let content: String?
        let type: PostType?
        let status: Status?
    }
}

extension BlogPost {
    struct DetailDTO: Content {
        let id: BlogPost.IDValue
        let title: String
        let excerpt: String
        let content: String
        let auther: User.AuthorDTO
        let status: Status
        let createdAt: Date?
        let updatedAt: Date?
        let tags: [Tag]
    }
    
    var detailDTO: DetailDTO {
        get throws {
            let id = try requireID()
            let authorDTO = try author.authorDTO
            return .init(id: id, title: title, excerpt: excerpt, content: content, auther: authorDTO, status: status, createdAt: createdAt, updatedAt: updatedAt, tags: tags)
        }
    }
    
    struct ListDTO: Content {
        let id: BlogPost.IDValue
        let title: String
        let updatedAt: Date
        let commentCount: Int
        let authorName: String
        let status: Status
        // Multiple tags is concatenated into one string, separated by commas
        let tags: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case updatedAt = "updated_at"
            case commentCount = "comment_count"
            case authorName = "author_name"
            case status = "status"
            case tags = "tags"
        }
    }
}
