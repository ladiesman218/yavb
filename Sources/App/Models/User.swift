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
    
    init(id: UUID? = nil, username: String, email: String? = nil, isEmailOn: Bool = false, phone: String? = nil, isPhoneOn: Bool = false, password: String) throws {
        self.id = id
        self.username = username
        self.email = email
        self.phone = phone
        self.isEmailOn = isEmailOn
        self.isPhoneOn = isPhoneOn
        let hashedPassword = try Bcrypt.hash(password)
        self.password = hashedPassword
    }
}

extension User {
    static let usernameLength = 4 ... 32
    static let passwordLength = 6 ... 256
    static let phoneRegex = "^(\\+[1-9]+(-[0-9]+)* )?[0]?[1-9][0-9\\- ][0-9]*$"
    static let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9]+\\.?[A-Za-z0-9]+\\.[A-Za-z]{2,64}$"
    
    struct FieldKeys {
        static let username: FieldKey = .init(stringLiteral: "username")
        static let email: FieldKey = .init(stringLiteral: "email")
        static let isEmailOn: FieldKey = .init(stringLiteral: "is_email_on")
        static let phone: FieldKey = .init(stringLiteral: "phone")
        static let isPhoneOn: FieldKey = .init(stringLiteral: "is_phone_on")
        static let password: FieldKey = .init(stringLiteral: "password")
    }
}

extension User {
    struct DTO: Codable {
        let id: UUID
        let username: String
        let email: String?
        let phone: String?
        let isEmailOn: Bool
        let isPhoneOn: Bool
    }
    var dto: DTO {
        get throws {
            let id = try requireID()
            return .init(id: id, username: username, email: email, phone: phone, isEmailOn: isEmailOn, isPhoneOn: isPhoneOn)
        }
    }
}

extension User {
    struct RegisterInput: Decodable {
        let contactInfo: String
        let username: String
        let password1: String
        let password2: String
        
        var user: User {
            get throws {
                if contactInfo.range(of: User.emailRegex, options: .regularExpression) != nil {
                    return try User(username: username, email: contactInfo, isEmailOn: true, password: password1)
                } else if contactInfo.range(of: User.phoneRegex, options: .regularExpression) != nil {
                    return try User(username: username, phone: contactInfo, isPhoneOn: true, password: password1)
                } else {
                    throw Abort(.badRequest)
                }
            }
        }
    }
}

extension User {
    enum NotificationMethod {
        case email
        case sms
        case all
    }
    var notificationMethod: NotificationMethod {
        if isEmailOn && isPhoneOn {
            return .all
        } else if isEmailOn {
            return .email
        } else {
            return .sms
        }
    }
}

extension User.RegisterInput: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("contactInfo", as: String.self, is: .pattern(User.phoneRegex) || .internationalEmail || .phoneNumber, customFailureDescription: "Invalid contact info")
        validations.add("username", as: String.self, is: .count(User.usernameLength))
        validations.add("password1", as: String.self, is: .count(User.passwordLength) && .ascii)
    }
}
