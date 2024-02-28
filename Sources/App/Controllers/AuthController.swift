//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/2/28.
//

import Vapor
import OpenAPIRuntime

struct AuthAPI: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "hi \(name)"))))
    }
}
