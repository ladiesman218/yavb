//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/13.
//

import Vapor
import Fluent

extension API {
    func createPost(_ input: Operations.createPost.Input) async throws -> Operations.createPost.Output {
        return .created(.init())
    }
}
