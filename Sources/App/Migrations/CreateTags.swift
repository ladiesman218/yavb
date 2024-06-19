import FluentPostgresDriver
import FluentSQL

struct CreateTags: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema(Tag.schema)
            .id()
            .field(Tag.FieldKeys.name, .string, .required)
            .unique(on: Tag.FieldKeys.name)
            .create()
        
        // Make sure name can't be pure space(s) and/or tab(s).
        let raw = SQLRaw("\(Tag.FieldKeys.name) !~ '^[ \t]*$'")
        let notPureControlLetters = DatabaseSchema.Constraint.sql(SQLTableConstraintAlgorithm.check(raw))
        try await database.schema(Tag.schema).constraint(notPureControlLetters).update()
        
        // Make sure lowercased new name can't be existing in current row's lowercased value
        if let sql  = database as? SQLDatabase {
            try await sql.raw("CREATE UNIQUE INDEX unique_lowercase_name_index ON \(unsafeRaw: Tag.schema) (LOWER(\(unsafeRaw: Tag.FieldKeys.name.description)))")
            .run()
        }
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tag.schema).delete()
    }
}
