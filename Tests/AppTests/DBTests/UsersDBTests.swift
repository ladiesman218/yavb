import XCTVapor
import NIOConcurrencyHelpers
@testable import App


final class UsersDBTests: XCTestCase {
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
    
    func testUserEmailRegex() async throws {
        let user = try User(username: "asdf", email: "asdf@asdf", password: "asdfasdf")
        user.isEmailOn = true
        user.isPhoneOn = false
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
    
    func testUserPhoneRegex() async throws {
        let user = try User(username: "asdf", phone: "+1-23 456789 ", password: "asdfasdf")
        user.isPhoneOn = true
        user.isEmailOn = false
        do {
            try await user.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "constraintName: phone_regex_check")
        }
        let count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 0)
        
        user.phone = "+123 4567890123"
        try await user.save(on: app.db)
        let allUsers = try await User.query(on: app.db).all()
        XCTAssertEqual(allUsers.count, 1)
        XCTAssertEqual(allUsers.first?.phone, user.phone)
    }
    
    func testContactsConstraints() async throws {
        // Test contact address can not both be nil
        let user = try User(username: "asdf", password: "asdfasdf")
        user.isPhoneOn = false
        user.isEmailOn = false
        do {
            try await user.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "constraintName: contact_not_both_null")
        }
        var count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 0)
        
        // Test email can't be null when isEmailOn is set to true
        user.phone = "123456789"
        user.isEmailOn = true
        do {
            try await user.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "constraintName: email_not_null")
        }
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 0)
        
        // Test phone number can't be null when isPhoneOn is set to true
        user.phone = nil
        user.email = "test@test.com"
        user.isPhoneOn = true
        do {
            try await user.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "constraintName: phone_not_null")
        }
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 0)
    }
    
    func testUniqueConstraints() async throws {
        // Test username uniqueness
        let user = try User(username: "asdf", email: "test@test.com", phone: "123456789", password: "asdfasdf")
        user.isPhoneOn = true
        user.isEmailOn = true
        try await user.save(on: app.db)
        
        let user2 = try User(username: "asdf", email: "test2@test.com", password: "asdfasdf")
        user2.isPhoneOn = false
        user2.isEmailOn = true
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
        user3.isPhoneOn = false
        user3.isEmailOn = true
        do {
            try await user3.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "unique constraint \"uq:users.email\"")
        }
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 1)
        
        // Test phone number uniqueness
        let user4 = try User(username: "哈哈呵呵", phone: "123456789", password: "asdfasdf")
        user4.isPhoneOn = true
        user4.isEmailOn = false
        do {
            try await user4.save(on: app.db)
        } catch {
            let errorString = String(reflecting: error)
            XCTAssertContains(errorString, "unique constraint \"uq:users.phone\"")
        }
        count = try await User.query(on: app.db).all().count
        XCTAssertEqual(count, 1)
    }
}
