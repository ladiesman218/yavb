
import Foundation
import Vapor
var siteName = "Yet Another Vapor Blog"
var shortName = "YAVB"
var domainName: URL {
    if try! Environment.detect() == .development {
        return .init(string: "http://localhost:8082")!
    } else {
        return .init(string: "")!
    }
}
let sessionMaxAge = 60 * 60 * 24 * 30 // 30 days
let jwtValidMinutes = 5
var jwtExpiration: Date {
    Date.now + 60 * Double(jwtValidMinutes)
}

let sessionCookieName = "yavb-session"

var webmasterExists = false
var allowRegistration = true
var allowComment = true
var commentNeedReview = true
var allowGuestPost = true
var postsNeedReview = false

