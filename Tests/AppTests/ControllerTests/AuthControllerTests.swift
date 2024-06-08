import XCTVapor

@testable import App
let app = Application(.testing)
final class AuthControllerTests: XCTestCase {
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
    
    
}
