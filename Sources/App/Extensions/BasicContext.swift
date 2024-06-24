import Vapor
import Leaf

class BasicContext: Encodable {
    let title: String
    var script: String? = nil
    let siteName: String = App.siteName
    let shortName: String = App.shortName
    init(title: String, script: String? = nil) {
        self.title = title
        self.script = script
    }
//    private enum CodingKeys: String, CodingKey {
//        case title, script, siteName, shortName
//    }
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(title, forKey: .title)
//        try container.encode(siteName, forKey: .siteName)
//        try container.encode(shortName, forKey: .shortName)
//        try container.encode(script, forKey: .script)
//    }
}

class PublicContext: BasicContext {
    let arbitary: String
    
    init(title: String, arbitary: String, script: String? = nil) {
        self.arbitary = arbitary
        super.init(title: title, script: script)
    }
//    private enum CodingKeys: String, CodingKey {
//        case posts
//    }
//    
//    override func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .posts)
//        try nestedContainer.encode(posts, forKey: .posts)
//        try super.encode(to: encoder)
//    }
}
struct HomeContext: Encodable {
    let title: String
    let script: String
    let siteName: String = App.siteName
    let shortName = App.shortName
    let posts: [BlogPost.DTO]
    
    init(title: String, script: String, posts: [BlogPost.DTO]) {
        self.title = title
        self.script = script
        self.posts = posts
    }
}
