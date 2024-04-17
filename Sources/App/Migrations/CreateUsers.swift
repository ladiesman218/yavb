//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/8.
//

import FluentSQL

struct CreateUsers: AsyncMigration {
    // MARK: - Field Constraints
    let emailRegexConstraint = SQLColumnConstraintAlgorithm.custom(SQLRaw("CONSTRAINT email_regex_check CHECK (\(User.FieldKeys.email) ~* '\(User.emailRegex)')"))
    let phoneRegexConstraint = SQLColumnConstraintAlgorithm.custom(SQLRaw("CONSTRAINT phone_regex_check CHECK (\(User.FieldKeys.phone) ~* '\(User.phoneRegex)')"))
    let usernameLengthConstraint = SQLColumnConstraintAlgorithm.custom(SQLRaw("CONSTRAINT username_length CHECK (LENGTH(\(User.FieldKeys.username)) BETWEEN \(User.usernameLength.lowerBound) AND \(User.usernameLength.upperBound))"))
    
    // MARK: - Table Constraints
    let contactNotBothNull = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT contact_not_both_null CHECK (\(User.FieldKeys.email) IS NOT NULL OR \(User.FieldKeys.phone) IS NOT NULL)")
    // is_On fields means whether a user want to receive notifications via the corresponding contact method, if it's on, address should be not null. But this shouldn't go the other way: if a contact string is not null, user may registered the address but turned of the notification setting for that address. So we only check for turned on settings shouldn't have a null value.
    let emailNotNull = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT email_not_null CHECK (\(User.FieldKeys.isEmailOn) IS FALSE OR \(User.FieldKeys.email) IS NOT NULL)")
    let phoneNotNull = DatabaseSchema.Constraint.sql(raw: "CONSTRAINT phone_not_null CHECK (\(User.FieldKeys.isPhoneOn) IS FALSE OR \(User.FieldKeys.phone) IS NOT NULL)")
    
    // MARK: - Functions
    func prepare(on database: any Database) async throws {
        
        try await database.schema(User.schema).id()
            .field(User.FieldKeys.email, .string, .sql(emailRegexConstraint)).unique(on: User.FieldKeys.email)
            .field(User.FieldKeys.isEmailOn, .bool, .required)
            .field(User.FieldKeys.phone, .string, .sql(phoneRegexConstraint)).unique(on: User.FieldKeys.phone)
            .field(User.FieldKeys.isPhoneOn, .bool, .required)
            .field(User.FieldKeys.username, .string, .required, .sql(usernameLengthConstraint)).unique(on: User.FieldKeys.username)
            .field(User.FieldKeys.password, .string, .required)
        
            .constraint(contactNotBothNull)
            .constraint(emailNotNull)
            .constraint(phoneNotNull)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}

