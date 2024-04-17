//
//  File.swift
//
//
//  Created by Lei Gao on 2024/2/28.
//

import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        auth.post("register", use: register)
    }
    
    func register(_ req: Request) async throws -> Response {
        let a = MessageType.email(address: "asdf@asdf.com")
        let encoder = JSONEncoder()
        let b = try! encoder.encode(a)
        let jsonString = String(data: b, encoding: .utf8)
        print(jsonString)
        
        try User.RegisterInput.validate(content: req)
        let input = try req.content.decode(User.RegisterInput.self)
        
        guard input.password1 == input.password2 else {
            throw Abort(.badRequest, reason: "Passwords don't match")
        }
        
        // Check db conflicts
        async let foundUsername = User.query(on: req.db).filter(\.$username == input.username).first()
        async let foundContact = User.query(on: req.db).group { group in
            group.filter(\.$email == input.contactInfo)
            group.filter(\.$phone == input.contactInfo)
        }.first()
        
        guard try await foundContact == nil else { throw Abort(.conflict, reason: "Contact info exists") }
        guard try await foundUsername == nil else { throw Abort(.conflict, reason: "Username exists") }
        
        let user = try input.user
        
        try await user.save(on: req.db)
        return Response(status: .created)
    }
    
}


