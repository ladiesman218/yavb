//
//  File.swift
//
//
//  Created by Lei Gao on 2024/2/28.
//

import Vapor
import Fluent
import OpenAPIRuntime

extension API {
    func register(_ input: Operations.register.Input) async throws -> Operations.register.Output {
        
        let registerInput: Components.Schemas.RegisterInput
        
        switch input.body {
            case .json(let json):
                registerInput = json
        }
        
        do {
            try Components.Schemas.RegisterInput.validate(content: request)
        } catch {
            let e = error as! ValidationsError
            return .badRequest(.init(body: .plainText(.init(stringLiteral: e.description))))
        }
        
//        guard registerInput.contactInfo == registerInput.value2.password2 else {
//            return .badRequest(.init(body: .plainText(.init(stringLiteral: "Passwords must match"))))
//        }
//        
//        guard try await User.query(on: db).filter(\.$email == registerInput.value1).first() == nil || registerInput.value1.self == nil else {
//            let reason = Components.Schemas.ServerConflictError.Email_space_has_space_been_space_taken.rawValue
//            return .conflict(.init(body: .plainText(.init(stringLiteral: reason))))
//        }
//        
//        guard try await User.query(on: db).filter(\.$phone == registerInput.phone).first() == nil || registerInput.phone == nil else {
//            let reason = Components.Schemas.ServerConflictError.Phone_space_number_space_has_space_been_space_taken.rawValue
//            return .conflict(.init(body: .plainText(.init(stringLiteral: reason))))
//        }
//        
//        guard try await User.query(on: db).filter(\.$username == registerInput.username).first() == nil else {
//            let reason = Components.Schemas.ServerConflictError.Username_space_has_space_been_space_taken.rawValue
//            return .conflict(.init(body: .plainText(.init(stringLiteral: reason))))
//        }
//        
//        let hashedPassword = try Bcrypt.hash(registerInput.password1)
//        let user = User(username: registerInput.username, email: registerInput.email, phone: "12312312", password: hashedPassword)
        
//        try await user.create(on: db)
        return .created(.init())
    }    
}
