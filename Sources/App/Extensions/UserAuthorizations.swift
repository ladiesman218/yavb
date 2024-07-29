import Foundation

struct UserAuthorizations: OptionSet {
    let rawValue: UInt8
    static let addComment = UserAuthorizations(rawValue: 1 << 0)
    // Approve or delete comments
    static let reviewComment = UserAuthorizations(rawValue: 1 << 1)
    static let addPost = UserAuthorizations(rawValue: 1 << 2)
    // Change posts status, edit or remove posts
    static let reviewPost = UserAuthorizations(rawValue: 1 << 3)
    static let banUser = UserAuthorizations(rawValue: 1 << 4)
    static let promoteAuthor = UserAuthorizations(rawValue: 1 << 5)
    static let promoteAdmin = UserAuthorizations(rawValue: 1 << 6)
    
    static let webmaster: UserAuthorizations = [.addComment, .reviewComment, addPost, .reviewPost, .banUser, .promoteAuthor, .promoteAdmin]
    static let admin: UserAuthorizations = [.addComment, .reviewComment, .addPost, .reviewPost, .banUser, .promoteAuthor]
    static let author: UserAuthorizations = [.addComment, .reviewComment, .addPost]
    static let subscriber: UserAuthorizations = [.addComment]
}
