import Vapor
import JWTKit

struct UserJWT: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case audience = "aud"
    }
    
    enum Subject: String, Codable {
        case activation, optLogin, changePW
    }
    
    let subject: Subject
    let expiration: ExpirationClaim = .init(value: jwtExpiration)
    let audience: AudienceClaim
    
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
