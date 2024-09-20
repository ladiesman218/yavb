import VaporSMTPKit
import Vapor
@preconcurrency import SMTPKitten

extension Application {
    static var defaultSMTPCredentials: SMTPCredentials {
        return SMTPCredentials(
            hostname: Environment.get("SMTP_SERVER") ?? "smtp.example.com",
            ssl: .startTLS(configuration: .default),
            email: Environment.get("SMTP_ACCOUNT") ?? "noreply@example.com",
            password: Environment.get("SMTP_PASSWORD") ?? "<Secret>"
        )
    }
}
extension Application {
    public func sendMail(
        _ mail: Mail,
        preventedDomains: Set<String> = ["example.com"]
    ) -> EventLoopFuture<Void> {
        return sendMails([mail], withCredentials: Self.defaultSMTPCredentials, preventedDomains: preventedDomains)
    }
    
}

extension Mail {
    static let sender = MailUser(name: "noreply", email: Environment.get("SMTP_ACCOUNT") ?? "noreply@example.com")
    init(
        to: Set<MailUser>,
        cc: Set<MailUser> = [],
        subject: String,
        contentType: ContentType,
        text: String
    ) {
        self.init(from: Self.sender, to: to, subject: subject, contentType: contentType, text: text)
    }
    
    enum Template {
        static let placeHolder = "${place_holder}"
        static let verificationCode = """
 <html><head></head>
 <body>
 <font size="3">
 <p>Your verification code:</p>
 <font size="6">
 <p>\(placeHolder)</p>
 </font>
 <p>This code will be valid in 5 minutes</p>
 </font>
 </body></html>
 """
//        static func verificationCode(for user: User) throws -> String {
//            guard let code = user.verificationCode else { throw Abort(.badRequest, reason: "No verification code found for user")}
//            
//            let res = Self.verificationCode.replacingOccurrences(of: placeHolder, with: code)
//            
//            return res
//        }
    }
}
