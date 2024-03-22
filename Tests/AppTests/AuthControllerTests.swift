//
//  ControllerTests.swift
//
//
//  Created by Lei Gao on 2024/3/19.
//

import Vapor
import XCTVapor
import HTTPTypes

@testable import App
final class AuthControllerTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        print("setting up")
    }
    override class func tearDown() {
        super.tearDown()
        print("tearing down")
    }
    
    let pathString = String(try! Servers.server1().relativePath.dropFirst() + "/auth")
    
//     func testRegister() async throws {
//         let app = Application(.testing)
//         try await configure(app)
//         defer { app.shutdown() }
        
//         let endpoint = pathString + "/register"
//         try app.testable().test(.GET, "openapi") { response in
//             XCTAssertEqual(response.status.code, 301)
//         }
//         try app.testable(method: .running(port: 8082)).test(.POST, endpoint, beforeRequest: { req in
//             try req.content.encode([
//                 "email": "asldkfj@asdf.csssssom",
//                 "username": "vapor",
//                 "password1": "asdfasdf",
//                 "password2": "asdfasdf"
//             ], as: .json)
//         }) { res in
//             print("😁")
//             print(res.body.string)
//             XCTAssertEqual(res.status, .created)
// //            XCTAssertEqual(res.body.string, Components.Schemas.ServerConflictError.Email_space_has_space_been_space_taken.rawValue)
//         }
// //        .test(.POST, "/register") { res in
// //            XCTAssertEqual(res.status, .unprocessableEntity)
// //            XCTAssertContains(res.body.string.replacingOccurrences(of: "\\", with: ""), "Missing \"Content-Type\" header")
// //        }.test(.POST, "/register", headers: ["Content-Type":"application/json"]) { res in
// //            XCTAssertEqual(res.status, .unprocessableEntity)
// //            XCTAssertContains(res.body.string, "Empty Body")
// //        }
    }
    
    
}
