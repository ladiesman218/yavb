import Fluent
import Foundation

final class BlogTagPivot: Model, @unchecked Sendable {
    @ID() var id: UUID?
    @Parent(key: FieldKeys.blogID) var blog: BlogPost
    @Parent(key: FieldKeys.tagID) var tag: Tag
    
    init() { }
    
    init(id: UUID? = nil, blogID: BlogPost.IDValue, tagID: Tag.IDValue) {
        self.id = id
        self.$blog.id = blogID
        self.$tag.id = tagID
    }
}

extension BlogTagPivot {
    static let schema = "blog_tag_pivot"
    enum FieldKeys {
        static let blogID: FieldKey = .init(stringLiteral: "blog_id")
        static let tagID: FieldKey = .init(stringLiteral: "tag_id")
    }
}
