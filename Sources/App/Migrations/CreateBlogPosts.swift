import FluentPostgresDriver

struct CreateBlogPosts: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let defaultPublished = SQLColumnConstraintAlgorithm.default(BlogPost.Status.published.rawValue)
        let defaultType = SQLColumnConstraintAlgorithm.default(BlogPost.PostType.post.rawValue)
        
        let postType = try await database.enum(BlogPost.FieldKeys.type.description)
            .case(BlogPost.PostType.post.rawValue)
            .case(BlogPost.PostType.page.rawValue)
            .create()
        let postStatus = try await database.enum(BlogPost.FieldKeys.status.description)
            .case(BlogPost.Status.draft.rawValue)
            .case(BlogPost.Status.published.rawValue)
            .case(BlogPost.Status.pendingReview.rawValue)
            .case(BlogPost.Status.rejected.rawValue)
            .create()
        
        try await database.schema(BlogPost.schema).id()
            .field(BlogPost.FieldKeys.title, .string, .required).unique(on: BlogPost.FieldKeys.title)
            .field(BlogPost.FieldKeys.excerpt, .string, .required)
            .field(BlogPost.FieldKeys.content, .string, .required).unique(on: BlogPost.FieldKeys.content)
            .field(BlogPost.FieldKeys.authorID, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(BlogPost.FieldKeys.type, postType, .required, .sql(defaultType))
            .field(BlogPost.FieldKeys.status, postStatus, .required, .sql(defaultPublished))
            .field(BlogPost.FieldKeys.createdAt, .datetime, .required)
            .field(BlogPost.FieldKeys.updatedAt, .datetime, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(BlogPost.schema).delete()
        try await database.enum(BlogPost.FieldKeys.type.description).delete()
        try await database.enum(BlogPost.FieldKeys.status.description).delete()
    }
}
