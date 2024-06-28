import Vapor
import LeafKit

struct PostsContext: Encodable {
    let title: String
    let posts: [BlogPost.DTO]
}

struct PostContext: Encodable {
    let post: BlogPost.DTO
}

struct MenuItem: Encodable {
    var icon: String? = nil
    let name: String
    let path: String
    var subItems: [MenuItem]? = nil
}
struct ManageSidebarCxt: Encodable {
    static let post: MenuItem = .init(icon: "substack", name: "Posts", path: "", subItems: [
        MenuItem(name: "All Posts", path: ""),
        .init(name: "Add New Post", path: "")
    ])
    static let media = MenuItem(icon: "substack", name: "Media", path: "", subItems: [
        MenuItem(name: "All Medias", path: ""),
        .init(name: "Add New Media", path: "")
    ])
    static let pages = MenuItem(icon: "substack", name: "Pages", path: "", subItems: [
        MenuItem(name: "All Pages", path: ""),
        .init(name: "Add New Page", path: "")
    ])
    static let comments = MenuItem(icon: "substack", name: "Comments", path: "", subItems: [
        MenuItem(name: "All Comments", path: ""),
        .init(name: "Add New Comment", path: "")
    ])
    static let users = MenuItem(icon: "substack", name: "Users", path: "", subItems: [
        MenuItem(name: "All Users", path: ""),
        .init(name: "Add New User", path: "")
    ])
    static let settings = MenuItem(icon: "substack", name: "Settings", path: "", subItems: [
        MenuItem(name: "All Posts", path: ""),
        .init(name: "Add New Post", path: "")
    ])
    let items = [post, media, pages, comments, users, settings]
}

struct ManageContext: Encodable {
    let sideBar = ManageSidebarCxt()
    var posts: [BlogPost.DTO]? = nil
    var pages: [BlogPost.DTO]? = nil
}
