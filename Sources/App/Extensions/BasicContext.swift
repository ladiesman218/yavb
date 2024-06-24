import Vapor
import Leaf

struct PublicContext: Encodable {
    let title: String
    let siteName: String = App.siteName
    let shortName = App.shortName
    let posts: [BlogPost.DTO]
    var script: String? = nil
    var jwt: String? = nil
    var userDTO: User.DTO? = nil
}

struct Managecontext: Encodable {
    
}
