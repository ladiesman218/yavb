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
    var app: Application!
    override func setUp() async throws {
        try await super.setUp()
        app = try Application.testable()
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
        app = nil
    }
    
    let pathString = String(try! Servers.server1().relativePath.dropFirst() + "/auth")
    
    func testRegister() async throws {
        let endpoint = pathString + "/register"
        try app.testable().test(.GET, "openapi") { response in
            XCTAssertEqual(response.status.code, 301)
        }
        try app.testable().test(.POST, endpoint, beforeRequest: { req in
            try req.content.encode([
                "email": "asdf@1234.",
                "username": "asd",
                "password1": "asdfasdf",
                "password2": "asdfasdfs"
            ], as: .json)
        }) { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertContains(res.body.string, "Email address is invalid")
//            XCTAssertContains(<#T##haystack: String?##String?#>, <#T##needle: String?##String?#>)
        }
        .test(.POST, endpoint, beforeRequest: { req in
            try req.content.encode([
                "email": "asdf@1234.com",
                "username": "asdf",
                "password1": "asdfasdf",
                "password2": "asdfasdfs"
            ], as: .json)
        }) { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertContains(res.body.string, "Passwords")
        }
        .test(.POST, endpoint, beforeRequest: { req in
            try req.content.encode([
                "email": "asdf@1234.com",
                "username": "asdf",
                "password1": "asdfasdf",
                "password2": "asdfasdf"
            ], as: .json)
        }) { res in
            XCTAssertEqual(res.status, .created)
            XCTAssertTrue(res.body.readableBytesView.isEmpty)
        }
        .test(.POST, endpoint, beforeRequest: { req in
            try req.content.encode([
                "email": "asdf@1234.com",
                "username": "vapor",
                "password1": "asdfasdf",
                "password2": "asdfasdf"
            ], as: .json)
        }) { res in
            XCTAssertEqual(res.status, .conflict)
            XCTAssertEqual(res.body.string, Components.Schemas.ServerConflictError.Email_space_has_space_been_space_taken.rawValue)
        }
        .test(.POST, endpoint, beforeRequest: { req in
            try req.content.encode([
                "email": "vapor@gmail.com",
                "username": "asdf",
                "password1": "asdfasdf",
                "password2": "asdfasdf"
            ], as: .json)
        }) { res in
            XCTAssertEqual(res.status, .conflict)
            XCTAssertEqual(res.body.string, Components.Schemas.ServerConflictError.Username_space_has_space_been_space_taken.rawValue)
        }
    }
    
    
}
