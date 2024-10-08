import FluentPostgresDriver

struct CreateUsers: AsyncMigration {
    // MARK: - Field Constraints
    let emailRegexConstraint = SQLColumnConstraintAlgorithm.custom(SQLRaw("CONSTRAINT email_regex_check CHECK (\(User.FieldKeys.email) ~* '\(User.emailRegex)')"))
    let usernameLengthConstraint = SQLColumnConstraintAlgorithm.custom(SQLRaw("CONSTRAINT username_length CHECK (LENGTH(\(User.FieldKeys.username)) BETWEEN \(User.usernameLength.lowerBound) AND \(User.usernameLength.upperBound))"))
    let defaultNotActivated = SQLColumnConstraintAlgorithm.default(false)
    let defaultRole = SQLColumnConstraintAlgorithm.default(User.Role.subscriber.rawValue)
#warning("Make sure one at most one webmaster can exist in db")

    // MARK: - Functions
    func prepare(on database: any Database) async throws {
        let role = try await database.enum(User.FieldKeys.role.description)
            .case(User.Role.webmaster.rawValue)
            .case(User.Role.admin.rawValue)
            .case(User.Role.author.rawValue)
            .case(User.Role.subscriber.rawValue)
            .create()
        
        try await database.schema(User.schema).id()
            .field(User.FieldKeys.email, .string, .required, .sql(emailRegexConstraint)).unique(on: User.FieldKeys.email)
            .field(User.FieldKeys.username, .string, .required, .sql(usernameLengthConstraint)).unique(on: User.FieldKeys.username)
            .field(User.FieldKeys.password, .string, .required)
            .field(User.FieldKeys.activated, .bool, .required, .sql(defaultNotActivated))
            .field(User.FieldKeys.role, role, .required, .sql(defaultRole))
            .field(User.FieldKeys.registerTime, .datetime, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
        try await database.enum(User.FieldKeys.role.description).delete()
    }
}

