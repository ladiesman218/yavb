import FluentPostgresDriver

struct CreateBlogTagPivot: AsyncMigration {

    func prepare(on database: any Database) async throws {
        try await database.schema(BlogTagPivot.schema).id()
            .field(BlogTagPivot.FieldKeys.blogID, .uuid, .required, .references(BlogPost.schema, "id", onDelete: .cascade))
            .field(BlogTagPivot.FieldKeys.tagID, .uuid, .required, .references(Tag.schema, "id", onDelete: .cascade))
            .unique(on: BlogTagPivot.FieldKeys.blogID, BlogTagPivot.FieldKeys.tagID)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(BlogTagPivot.schema).delete()
    }
}
