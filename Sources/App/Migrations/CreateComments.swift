import FluentPostgresDriver

struct CreateComments: AsyncMigration {
    let defaultPending = SQLColumnConstraintAlgorithm.default(false)
    func prepare(on database: any Database) async throws {
        try await database.schema(Comment.schema).id()
            .field(Comment.FieldKeys.userID, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(Comment.FieldKeys.postID, .uuid, .required, .references(BlogPost.schema, "id", onDelete: .cascade))
            .field(Comment.FieldKeys.content, .string, .required)
            .field(Comment.FieldKeys.status, .bool, .required, .sql(defaultPending))
            .field(Comment.FieldKeys.updatedTime, .datetime, .required)
            .create()
        
        // Make sure content can't be pure space(s) and/or tab(s).
        let raw = SQLRaw("\(Comment.FieldKeys.content) !~ '^[ \t]*$'")
        let notPureControlLetters = DatabaseSchema.Constraint.sql(SQLTableConstraintAlgorithm.check(raw))
        try await database.schema(Comment.schema).constraint(notPureControlLetters).update()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Comment.schema).delete()
    }
}
