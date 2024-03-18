//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/8.
//

import Vapor
import Fluent

final class User: Model, Content {
    
    
    static let schema: String = "users"
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.username) var username: String
    @Field(key: FieldKeys.email) var email: String
    @Field(key: FieldKeys.password) var password: String
    
    init() {}
    
    init(id: UUID? = nil, username: String, email: String, password: String) {
        self.id = id
        self.username = username
        self.email = email
        self.password = password
    }
}

extension User {
    static let usernameLength = 4 ... 32
    static let passwordLength = 6 ... 256
    
    struct FieldKeys {
        static let username: FieldKey = .init(stringLiteral: "username")
        static let email: FieldKey = .init(stringLiteral: "email")
        static let password: FieldKey = .init(stringLiteral: "password")
    }
}

extension Components.Schemas.RegisterInput: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        
        validations.add("email", as: String.self, is: .internationalEmail, required: true, customFailureDescription: "Email address is invalid")
        validations.add("username", as: String.self, is: .count(4...32) && .alphanumeric)
        validations.add("password1", as: String.self, is: .count(6...256))
    }
}
