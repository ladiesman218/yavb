//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/8.
//

import Fluent

struct CreateUsers: AsyncMigration {
    let emailAddressConstraint = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT email_regex_check CHECK (\(User.FieldKeys.email) ~* '^[A-Z0-9+_.-]+@[A-Z0-9.-]+\\.[A-Z0-9]+$')")
    let phoneNumberConstraint = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT phone_regex_check CHECK (\(User.FieldKeys.phone) ~* '\(Message.Recipient.phoneRegex)')")
    let contactNotBothNull = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT contact_not_both_null CHECK (\(User.FieldKeys.email) IS NOT NULL OR \(User.FieldKeys.phone) IS NOT NULL)")
    let usernameLengthConstraint = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT username_length CHECK (LENGTH(\(User.FieldKeys.username)) BETWEEN \(User.usernameLength.lowerBound) AND \(User.usernameLength.upperBound))")

    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema).id()
            .field(User.FieldKeys.email, .string).unique(on: User.FieldKeys.email).constraint(emailAddressConstraint)
            .field(User.FieldKeys.isEmailOn, .bool, .required)
            .field(User.FieldKeys.phone, .string).unique(on: User.FieldKeys.phone).constraint(phoneNumberConstraint)
            .field(User.FieldKeys.isPhoneOn, .bool, .required)
            .field(User.FieldKeys.username, .string, .required).unique(on: User.FieldKeys.username).constraint(usernameLengthConstraint)
            .field(User.FieldKeys.password, .string, .required)
            .constraint(contactNotBothNull)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}

