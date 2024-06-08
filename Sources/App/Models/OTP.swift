import Vapor
import Fluent

final class OTP: Model, Content, @unchecked Sendable {
    static let schema: String = "otp_passwords"
    
    struct FieldKeys {
        static let user: FieldKey = .init(stringLiteral: "user_id")
        static let otp: FieldKey = .init(stringLiteral: "otp")
    }
    @ID() var id: UUID?
    @Parent(key: FieldKeys.user) var user: User
    @Field(key: FieldKeys.otp) var otp: String

    init() {}
    
    init(id: UUID? = nil, user: User, otp: String) {
        self.id = id
        self.user = user
        self.otp = otp
    }
}
