import Vapor
import JWT

//struct TestPayload: JWTPayload {
//    // Maps the longer Swift property names to the
//    // shortened keys used in the JWT payload.
//    enum CodingKeys: String, CodingKey {
//        case subject = "sub"
//        case expiration = "exp"
//        case isAdmin = "admin"
//    }
//    
//    // The "sub" (subject) claim identifies the principal that is the
//    // subject of the JWT.
//    var subject: SubjectClaim
//    
//    // The "exp" (expiration time) claim identifies the expiration time on
//    // or after which the JWT MUST NOT be accepted for processing.
//    var expiration: ExpirationClaim
//    
//    // Custom data.
//    // If true, the user is an admin.
//    var isAdmin: Bool
//    
//    // Run any additional verification logic beyond
//    // signature verification here.
//    // Since we have an ExpirationClaim, we will
//    // call its verify method.
//    func verify(using signer: JWTSigner) throws {
//        try self.expiration.verifyNotExpired()
//    }
//}

struct JWTSessionToken: Content, Authenticatable, JWTPayload {
    
    // Constants
    static let expirationTime: TimeInterval = 60 * 5
    static let subject = "auth"
    
    // Token Data
    let subject: SubjectClaim
    let audience: AudienceClaim
    let expiration: ExpirationClaim
    var userId: User.IDValue
    
    init(userId: User.IDValue) {
        self.subject = SubjectClaim(value: Self.subject)
        self.audience = AudienceClaim(value: [userId.uuidString])
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Self.expirationTime))
    }
    
    init(user: User) throws {
        self.subject = SubjectClaim(value: Self.subject)
        self.audience = try AudienceClaim(value: [user.requireID().uuidString])
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Self.expirationTime))
    }
    
    func verify(using signer: some JWTAlgorithm) async throws {
        guard subject.value == Self.subject else { throw Abort(.unauthorized) }
        try audience.verifyIntendedAudience(includes: userId.uuidString)
        try expiration.verifyNotExpired()
    }
}

struct ClientTokenResponse: Content {
    var token: String
}
