import Vapor
import Fluent
import JWTKit

final class User: Model, Content, @unchecked Sendable {
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.username) var username: String
    @Field(key: FieldKeys.email) var email: String
    @Field(key: FieldKeys.password) var password: String
    @Field(key: FieldKeys.activated) var activated: Bool
    @Enum(key: FieldKeys.role) var role: Role
    @Timestamp(key: FieldKeys.registerTime, on: .create) var registerTime: Date?
    @Children(for: \OTP.$user) var otps: [OTP]
    @Children(for: \BlogPost.$author) var posts: [BlogPost]
    @Children(for: \Comment.$user) var comments: [Comment]
    
    init() {}
    
    init(id: UUID? = nil, username: String, email: String, password: String, activated: Bool = false, role: Role = .subscriber) throws {
        self.id = id
        self.username = username
        self.email = email
        let hashedPassword = try Bcrypt.hash(password)
        self.password = hashedPassword
        self.activated = activated
        self.role = role
    }
}

extension User {
    static let schema: String = "users"
    
    static let usernameLength = 4 ... 32
    static let passwordLength = 6 ... 256
    static let emailRegex = "^[A-Z0-9a-z._%+-]+@([A-Za-z0-9]+[-.]?)*[A-Za-z0-9]+\\.[A-Za-z]{2,64}$"
    static let phoneRegex: String = "(\\+[1-9]+(-[0-9]+)* )?[0]?[1-9][0-9\\- ][0-9]*$"
    
    struct FieldKeys {
        static let username: FieldKey = .init(stringLiteral: "username")
        static let email: FieldKey = .init(stringLiteral: "email")
        static let password: FieldKey = .init(stringLiteral: "password")
        static let activated: FieldKey = .init(stringLiteral: "activated")
        static let role: FieldKey = .init(stringLiteral: "role")
        static let registerTime: FieldKey = .init(stringLiteral: "register_time")
    }
}

extension User {
    struct DTO: Codable {
        let id: UUID
        let username: String
        let email: String?
        let activated: Bool
        let registerTime: Date
        let role: Role
    }
    var dto: DTO {
        get throws {
            let id = try requireID()
            guard let registerTime = registerTime else {
                throw Abort(.internalServerError, reason: "Can not get register time for user: \(id.uuidString)")
            }
            return .init(id: id, username: username, email: email, activated: activated, registerTime: registerTime, role: role)
        }
    }
    
    // Less info than User.DTO
    struct AuthorDTO: Codable {
        let id: UUID
        let username: String
    }
    
    var authorDTO: AuthorDTO {
        get throws {
            let id = try requireID()
            return .init(id: id, username: username)
        }
    }
}

extension User {
    struct LoginInput: Codable {
        let username: String
        let password: String
    }
    struct RegisterInput: Decodable, Validatable {
        let email: String
        let username: String
        let password1: String
        let password2: String
        
        func makeUser(req: Request) async throws -> User {
            // Check db conflicts
            async let noConflictEmail = try await User.query(on: req.db).filter(\.$email == email).count() == 0
            async let noConflictUsername = try await User.query(on: req.db).filter(\.$username == username).count() == 0
            // Input validate
            guard password1 == password2 else {
                throw Abort(.badRequest, reason: "Passwords don't match")
            }
            try Self.validate(content: req)
           
            guard try await noConflictEmail else { throw Abort(.conflict, reason: "Email exists") }
            guard try await noConflictUsername else { throw Abort(.conflict, reason: "Username exists")}
            return try User(username: username, email: email, password: password1)
        }
        
        static func validations(_ validations: inout Vapor.Validations) {
            validations.add("email", as: String.self, is: .pattern(User.emailRegex), customFailureDescription: "Invalid contact info")
            validations.add("username", as: String.self, is: .count(User.usernameLength))
            validations.add("password1", as: String.self, is: .count(User.passwordLength) && .ascii)
        }
    }
}

extension User {
    func genNewOTP(_ req: Request) async throws -> String {
        let otp = OTP()
        otp.$user.id = try self.requireID()
        let otpString = TOTP.generate(key: .init(size: .bits128), digest: .sha256, time: Date.now)
        otp.otp = otpString
        try await self.$otps.create(otp, on: req.db)
        return otpString
    }
    
    func generateJWT(_ req: Request, subject: UserJWT.Subject) async throws -> String {
        let id = try self.requireID()
        let payload = UserJWT(subject: subject, expiration: .init(value: jwtExpiration), audience: .init(stringLiteral: id.uuidString))
        let jwt: String
        if subject == .changePW {
            let keyCollection = await JWTKeyCollection().add(hmac: .init(from: self.password), digestAlgorithm: .sha256)
            jwt = try await keyCollection.sign(payload)
        } else {
            jwt = try await req.jwt.sign(payload)
        }
        return jwt
    }
}

extension User {
    enum Role: String, Codable, CaseIterable {
        case webmaster
        case admin
        case author
        case subscriber
        var authorizations: UserAuthorizations {
            switch self {
                case .webmaster:
                    return UserAuthorizations.webmaster
                case .admin:
                    return UserAuthorizations.admin
                case .author:
                    return UserAuthorizations.author
                case .subscriber:
                    return UserAuthorizations.subscriber
            }
        }
    }
    
    
}
