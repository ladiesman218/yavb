import XCTVapor
import NIOConcurrencyHelpers

@testable import App

final class AppTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        print("setting up")
    }
    override class func tearDown() {
        super.tearDown()
        print("tearing down")
    }
    
    func testApplicationStop() throws {
        let test = Environment(name: "testing", arguments: ["vapor"])
        let app = Application(test)
        defer { app.shutdown() }
        app.environment.arguments = ["serve"]
        app.http.server.configuration.port = 0
        try app.start()
        guard let running = app.running else {
            XCTFail("app started without setting 'running'")
            return
        }
        running.stop()
        try running.onStop.wait()
    }
    
    func testLifecycleHandler() throws {
        final class Foo: LifecycleHandler {
            let willBootFlag: NIOLockedValueBox<Bool>
            let didBootFlag: NIOLockedValueBox<Bool>
            let shutdownFlag: NIOLockedValueBox<Bool>
            
            init() {
                self.willBootFlag = .init(false)
                self.didBootFlag = .init(false)
                self.shutdownFlag = .init(false)
            }
            
            func willBoot(_ application: Application) throws {
                self.willBootFlag.withLockedValue { $0 = true }
            }
            
            func didBoot(_ application: Application) throws {
                self.didBootFlag.withLockedValue { $0 = true }
            }
            
            func shutdown(_ application: Application) {
                self.shutdownFlag.withLockedValue { $0 = true }
            }
        }
        
        let app = Application(.testing)
        
        let foo = Foo()
        app.lifecycle.use(foo)
        
        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        
        try app.boot()
        
        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        
        app.shutdown()
        
        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), true)
    }
    
    func testThrowDoesNotCrash() throws {
        enum Static {
            static let app: NIOLockedValueBox<Application?> = .init(nil)
        }
        Static.app.withLockedValue { $0 = Application(.testing) }
        Static.app.withLockedValue { $0 = nil }
    }
    
    func testSwiftError() throws {
        struct Foo: Error { }
        
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.get("error") { req -> String in
            throw Foo()
        }
        
        try app.testable().test(.GET, "/error") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }
    
    func testAsyncKitExport() throws {
        let eventLoop: EventLoop = EmbeddedEventLoop()
        let a = eventLoop.makePromise(of: Int.self)
        let b = eventLoop.makePromise(of: Int.self)
        
        let c = [a.futureResult, b.futureResult].flatten(on: eventLoop)
        
        a.succeed(1)
        b.succeed(2)
        
        try XCTAssertEqual(c.wait(), [1, 2])
    }
    
    func testBoilerplate() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.get("hello") { req in
            "Hello, world!"
        }
        
        app.environment.arguments = ["serve"]
        app.http.server.configuration.port = 0
        try app.start()
        
        XCTAssertNotNil(app.http.server.shared.localAddress)
        guard let localAddress = app.http.server.shared.localAddress,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        
        let res = try app.client.get("http://localhost:\(port)/hello").wait()
        XCTAssertEqual(res.body?.string, "Hello, world!")
    }
    
    func testAutomaticPortPickingWorks() {
        let app = Application(.testing)
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 0
        defer { app.shutdown() }
        
        app.get("hello") { req in
            "Hello, world!"
        }
        
        XCTAssertNil(app.http.server.shared.localAddress)
        
        app.environment.arguments = ["serve"]
        XCTAssertNoThrow(try app.start())
        
        XCTAssertNotNil(app.http.server.shared.localAddress)
        guard let localAddress = app.http.server.shared.localAddress,
              let ip = localAddress.ipAddress,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        
        XCTAssertEqual("127.0.0.1", ip)
        XCTAssertGreaterThan(port, 0)
        
        XCTAssertEqual("Hello, world!",
                       try app.client.get("http://localhost:\(port)/hello").wait().body?.string)
    }
    
    func testConfigurationAddressDetailsReflectedAfterBeingSet() throws {
        let app = Application(.testing)
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 0
        defer { app.shutdown() }
        
        struct AddressConfig: Content {
            let hostname: String
            let port: Int
        }
        
        app.get("hello") { req -> AddressConfig in
            let config = AddressConfig(hostname: req.application.http.server.configuration.hostname, port: req.application.http.server.configuration.port)
            return config
        }
        
        app.environment.arguments = ["serve"]
        XCTAssertNoThrow(try app.start())
        
        XCTAssertNotNil(app.http.server.shared.localAddress)
        XCTAssertEqual("0.0.0.0", app.http.server.configuration.hostname)
        
        guard let localAddress = app.http.server.shared.localAddress,
              localAddress.ipAddress != nil,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        let response = try app.client.get("http://localhost:\(port)/hello").wait()
        let returnedConfig = try response.content.decode(AddressConfig.self)
        XCTAssertEqual(returnedConfig.hostname, "0.0.0.0")
    }
    
    func testConfigurationAddressDetailsReflectedWhenProvidedThroughServeCommand() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        struct AddressConfig: Content {
            let hostname: String
            let port: Int
        }
        
        app.get("hello") { req -> AddressConfig in
            let config = AddressConfig(hostname: req.application.http.server.configuration.hostname, port: req.application.http.server.configuration.port)
            return config
        }
        
        app.environment.arguments = ["vapor", "serve", "--hostname", "0.0.0.0", "--port", "3000"]
        XCTAssertNoThrow(try app.start())
        
        XCTAssertNotNil(app.http.server.shared.localAddress)
        XCTAssertEqual("0.0.0.0", app.http.server.configuration.hostname)
        XCTAssertEqual(3000, app.http.server.configuration.port)
        
        guard let localAddress = app.http.server.shared.localAddress,
              localAddress.ipAddress != nil,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        let response = try app.client.get("http://localhost:\(port)/hello").wait()
        let returnedConfig = try response.content.decode(AddressConfig.self)
        XCTAssertEqual(returnedConfig.hostname, "0.0.0.0")
        XCTAssertEqual(returnedConfig.port, 3000)
    }
}
