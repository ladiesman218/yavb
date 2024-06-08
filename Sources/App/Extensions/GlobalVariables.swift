
import Foundation
import Vapor
let siteName = "Yet Another Vapor Blog"
var domainName: URL {
    if try! Environment.detect() == .development {
        return .init(string: "http://localhost:8082")!
    } else {
        return .init(string: "")!
    }
}
let sessionMaxAge = 60 * 60 * 24 * 30 // 30 days
var jwtExpiration: Date {
    Date.now + 60 * 5
}

