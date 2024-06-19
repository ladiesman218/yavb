import Vapor

struct Template {
    let string: String
    
    static let accountActivation = Self(string:"""
 <html><head></head>
 <body>
 <font size="5"><p>Welcome to \(siteName)</p>
 <p>Visit <a href="\(domainName)/auth/activate/\(Message.placeHolder)">this link</a> to activate your <strong>\(siteName)</strong> account</p>
 <p>Or paste the following URL into your browser:</p>
 <p>\(domainName)/auth/activate/\(Message.placeHolder)</p>
 </font>
 <p>The link will be valid for the next 5 minutes</p>
 <p>If you didn't register an account, please ignore this email.</p>
 </body></html>
""")

    static let otpPassword = Self(string: """
 <html><head></head>
 <body>
 <font size="5"><p>You just requested an one time password for \(siteName):</p>
 <p>\(Message.placeHolder)</p>
 </font>
 <p>This password will be valid for the next 5 minutes and 1 time use</p>
 <p>If you didn't request an password, please ignore this email.</p>
 </body></html>
""")
    
    static let changePW = Self(string:"""
 <html><head></head>
 <body>
 <font size="5"><p>You just requested to change password for \(siteName):</p>
 <p>Visit <a href="\(domainName)/auth/changePW/\(Message.placeHolder)">this link</a> to change your new password</p>
 </font>
 <p>The link will be valid for the next 5 minutes</p>
 <p>If you didn't request changing password, please ignore this email.</p>
 </body></html>
""")
}

struct Message: Content {
    static let placeHolder = "${placeHolder}"
    let string: String
    init (placeHolders: [String], template: Template, removeHTML: Bool = false) throws {
        var messageString = removeHTML ? template.string.htmlRemoved : template.string
        guard !template.string.isEmpty else {
            throw Abort(.badRequest, reason: "Message template can not be empty")
        }
        // Make sure number of placeholders are identical in both array and template
        guard placeHolders.count == template.string.countOccurrences(of: Self.placeHolder) else {
            throw Abort(.badRequest, reason: "Message template and placeholder numbers don't match")
        }
        
        placeHolders.forEach {
            messageString = messageString.replacing(Self.placeHolder, with: $0, maxReplacements: 1)
        }
        self.string = messageString
    }
}
