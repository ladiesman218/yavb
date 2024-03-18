//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/8.
//

import Fluent

struct CreateUsers: AsyncMigration {
    let emailAddressConstraint = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT email_regex_check CHECK (\(User.FieldKeys.email) ~* '\(emailAddressRegex)')")
    
    let usernameLengthConstraint = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT username_length CHECK (LENGTH(\(User.FieldKeys.username)) BETWEEN \(User.usernameLength.lowerBound) AND \(User.usernameLength.upperBound))")

    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema).id()
            .field(User.FieldKeys.email, .string, .required).unique(on: User.FieldKeys.email).constraint(emailAddressConstraint)
            .field(User.FieldKeys.username, .string, .required).unique(on: User.FieldKeys.username).constraint(usernameLengthConstraint)
            .field(User.FieldKeys.password, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}

