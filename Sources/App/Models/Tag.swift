import Vapor
import FluentKit

final class Tag: Model, Content, @unchecked Sendable {
    @ID() var id: UUID?
    @Field(key: FieldKeys.name) var name: String
    @Siblings(through: BlogTagPivot.self, from: \.$tag, to: \.$blog) var blogposts: [BlogPost]
    
    init() {}
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag {
    static let schema = "tags"

    enum FieldKeys {
        static let name: FieldKey = .init(stringLiteral: "name")
    }
}
//extension Tag: Equatable {
//    static func ==(lhs: Tag, rhs: Tag) -> Bool {
//        return lhs.name == rhs.name
//    }
//}
