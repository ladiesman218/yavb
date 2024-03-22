//
//  File.swift
//  
//
//  Created by Lei Gao on 2024/3/21.
//

import Vapor
import XCTVapor
@testable import App

extension Application {
    static func testable() throws -> Application {
        
        let app = Application(.testing)
        
        try configure(app)
        
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        
        return app
    }
}
