import XCTVapor
import NIOConcurrencyHelpers
@testable import App


final class UsersDBTests: XCTestCase {
    var app: Application!
    override func setUp() async throws {
        try await super.setUp()
        app = try await Application.testable()
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
        app = nil
    }
    
    func testUserEmailRegex() async throws {
        let user = try User(username: "asdf", email: "asdf@asdf", password: "asdfasdf")
        do {
            try await user.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "constraintName: email_regex_check")
        }
        let count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 0)
        
        user.email = "asdf@asdf.com"
        try await user.save(on: app.db)
        let allUsers = try await User.query(on: app.db).all()
        XCTAssertEqual(allUsers.count, 1)
        XCTAssertEqual(allUsers.first?.email, user.email)
        // Test password is not stored in plain text
        XCTAssertNotEqual(allUsers.first?.password, "asdfasdf")
    }
    
    func testUniqueConstraints() async throws {
        // Test username uniqueness
        let user = try User(username: "asdf", email: "test@test.com", password: "asdfasdf")
        try await user.save(on: app.db)
        
        let user2 = try User(username: "asdf", email: "test2@test.com", password: "asdfasdf")
        do {
            try await user2.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "unique constraint \"uq:users.username\"")
        }
        var count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 1)
        
        // Test email uniqueness
        let user3 = try User(username: "哈哈呵呵", email: "test@test.com", password: "asdfasdf")
        do {
            try await user3.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "unique constraint \"uq:users.email\"")
        }
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 1)
        
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 1)
    }
}
