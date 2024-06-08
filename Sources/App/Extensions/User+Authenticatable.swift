import Vapor
import Fluent



// The default implementation only allows one field in db to be used as username. Here we wanna use either one from these 3: username, email or phone number. So everything in the following protocol conformance is required and default, except for 1 we've customized: authenticator() function now returns a customized UserAuthenticator instance instead of ModelAuthenticatable's default implementation.
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    public static func credentialsAuthenticator( database: DatabaseID? = nil ) -> AsyncAuthenticator {
        UserBasicAuthenticator()
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(basic: Vapor.BasicAuthorization, for request: Vapor.Request) async throws {
        guard let user = try await User.query(on: request.db).group(.or, { group in
            group.filter(\.$username == basic.username)
            group.filter(\.$email == basic.username)
        }).first()
        else { return }
        
        guard try user.verify(password: basic.password) else { return }
        request.auth.login(user)
    }
}

// Apply the session middleware globally in configure.swift and session authenticator in all frontend routes
extension User: ModelSessionAuthenticatable { }
