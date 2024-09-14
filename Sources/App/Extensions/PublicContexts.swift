import Vapor
import Fluent
import LeafKit

struct BasicCtx: Encodable {
    let title: String
    let description: String
    let shortName: String
    let siteName: String
    init(title: String = "", description: String = "") {
        self.title = title
        self.description = description
        self.shortName = App.shortName
        self.siteName = App.siteName
    }
}

protocol Renderable: Encodable {
    var basicCtx: BasicCtx { get }
    var js: String? { get set }
}

struct EmptyCtx: Renderable {
    let basicCtx = BasicCtx()
    var js: String? = nil
}
struct PublicPostListCtx: Renderable {
    let basicCtx: BasicCtx
    var js: String? = nil
    let posts: [BlogPost.DetailDTO]
}

struct PublicPostDetailCtx: Renderable {
    let basicCtx: BasicCtx
    var js: String? = nil
    let post: BlogPost.DetailDTO
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

struct StatusPostsCount: Codable {
    let published: Int
    let draft: Int
    let pendingReview: Int
    let rejected: Int
}

struct ManagePostsListContext: Renderable {
    let sideBar = ManageSidebarCxt()
    let statusPostsCount: StatusPostsCount
    let basicCtx: BasicCtx
    var js: String? = nil
    let posts: Page<BlogPost.ListDTO>
}

// Could be used when creating new post, so post is optional.
struct ManagePostContext: Renderable {
    let sideBar = ManageSidebarCxt()
    let basicCtx: BasicCtx
    var js: String? = nil
    let post: BlogPost.DetailDTO?
}
