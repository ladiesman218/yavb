import Vapor
import Fluent

final class Comment: Model, Content, @unchecked Sendable {
    static let schema: String = "comments"
    
    @ID() var id: UUID?
    @Parent(key: FieldKeys.userID) var user: User
    @Parent(key: FieldKeys.postID) var post: BlogPost
    @Field(key: FieldKeys.content) var content: String
    @Field(key: FieldKeys.status) var status: Bool
    @Timestamp(key: FieldKeys.updatedTime, on: .update) var updatedTime: Date?
    
    init() {}
    
    init(id: Comment.IDValue? = nil, userID: User.IDValue, postID: BlogPost.IDValue, content: String, status: Bool = false) {
        self.id = id
        self.$user.id = userID
        self.$post.id = postID
        self.content = content
        self.status = status
    }
}

extension Comment {
    struct FieldKeys {
        static let userID: FieldKey = .init(stringLiteral: "user_id")
        static let postID: FieldKey = .init(stringLiteral: "post_id")
        static let content: FieldKey = .init(stringLiteral: "content")
        static let status: FieldKey = .init(stringLiteral: "status")
        static let updatedTime: FieldKey = .init(stringLiteral: "updated_time")
    }
    
    struct DTO: Codable {
        let id: Comment.IDValue
        let user: User.AuthorDTO
        let content: String
        let status: Bool
        let updatedTime: Date
    }
    var dto: DTO {
        get throws {
            let id = try self.requireID()
            let userDTO = try user.authorDTO
            return .init(id: id, user: userDTO, content: content, status: status, updatedTime: updatedTime!)
        }
    }
}
