import Foundation
import Vapor

let sessionMaxAge = 60 * 60 * 24 * 30 // 30 days
let jwtValidMinutes = 5
var jwtExpiration: Date {
    Date.now + 60 * Double(jwtValidMinutes)
}

let sessionCookieName = "yavb-session"

nonisolated(unsafe) var webmasterExists = false
//let allowRegistration = true
//let allowGuestPost = true
//let allowComment = true
//let commentNeedReview = true
//let postsNeedReview = false

