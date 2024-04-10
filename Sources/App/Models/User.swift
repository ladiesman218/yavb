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
    @OptionalField(key: FieldKeys.email) var email: String?
    @Field(key: FieldKeys.isEmailOn) var isEmailOn: Bool
    @OptionalField(key: FieldKeys.phone) var phone: String?
    @Field(key: FieldKeys.isPhoneOn) var isPhoneOn: Bool
    @Field(key: FieldKeys.password) var password: String
    
    init() {}
    
    init(id: UUID? = nil, username: String, email: String?, phone: String?, password: String) {
        self.id = id
        self.username = username
        self.email = email
        self.phone = phone
        self.isEmailOn = email != nil
        self.isPhoneOn = phone != nil
        self.password = password
    }
}

extension User {
    static let usernameLength = 4 ... 32
    static let passwordLength = 6 ... 256
    
    struct FieldKeys {
        static let username: FieldKey = .init(stringLiteral: "username")
        static let email: FieldKey = .init(stringLiteral: "email")
        static let isEmailOn: FieldKey = .init(stringLiteral: "is_email_on")
        static let phone: FieldKey = .init(stringLiteral: "phone")
        static let isPhoneOn: FieldKey = .init(stringLiteral: "is_phone_on")
        static let password: FieldKey = .init(stringLiteral: "password")
    }
}

extension Components.Schemas.RegisterInput: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("email", as: String.self, is: .internationalEmail, required: false, customFailureDescription: "Email address is invalid")
        validations.add("phone", as: String.self, is: .pattern(Message.Recipient.phoneRegex), required: false, customFailureDescription: "Phone number is invalid")
//        validations.add("email", as: String.self, is: .init(validate: { data in
//            data == nil
//        }))
        
//        validations.add("username", as: String.self, is: .count(4...32))
        validations.add("password1", as: String.self, is: .count(6...256) && .alphanumeric)
    }
}
