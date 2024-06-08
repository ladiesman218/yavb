import Fluent

struct CreateOTPs: AsyncMigration {
    func prepare(on database: any FluentKit.Database) async throws {
        try await database.schema(OTP.schema).id()
            .field(OTP.FieldKeys.user, .uuid, .required)
            .field(OTP.FieldKeys.otp, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(OTP.schema).delete()
    }
}
