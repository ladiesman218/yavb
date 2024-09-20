import Vapor
import Fluent
import SMTPKitten
import JWTKit

struct AuthController: RouteCollection {
    
    static func sendActivationEmail(_ req: Request, email: String) async throws {
        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        guard user.activated == false else { throw Abort(.badRequest, reason: "Already activated") }
        let jwt = try await user.generateJWT(req, subject: UserJWT.Subject.activation)
        let host = try req.host
        let content = try await req.render("EmailTemplates/AccountActivation", EmailCtx(host: host, jwt: jwt))
        guard let text = content.data.getString(at: 0, length: content.data.readableBytes) else {
            throw Abort(.internalServerError, reason: "Unable to generate account activation email content")
        }
        let mail = Mail(to: [.init(name: user.username, email: user.email)], subject: "\(req.application.configuration.siteName) Registration", contentType: .html, text: text)
        let _ = req.application.sendMail(mail)
    }
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        auth.post("register", use: register)
        auth.get("activate", ":jwt", use: activate)
        auth.post("resend-activate", use: resendActivationLink)
        auth.post("requestOTP", use: requestOTP)
        auth.grouped([User.credentialsAuthenticator()]).post("login", use: login)
        let sessionProtected = auth.grouped([User.sessionAuthenticator(), User.guardMiddleware()])
        sessionProtected.post("logout", use: logout)
        auth.post("otpLogin", use: otpLogin)
        auth.post("PWchange", use: requestPWChange)
        auth.post("changePW",":jwt", use: changePW)
    }
    
    func register(_ req: Request) async throws -> HTTPResponseStatus {
        let input = try req.content.decode(User.RegisterInput.self)
        
        let user = try await input.makeUser(req: req)
        try await user.save(on: req.db)
        try await Self.sendActivationEmail(req, email: user.email)
        return .created
    }
    
    func resendActivationLink(_ req: Request) async throws -> HTTPResponseStatus {
        struct Info: Codable { let email: String }
        let email = try req.content.decode(Info.self).email
        guard email.range(of: User.emailRegex, options: .regularExpression) != nil else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }
        try await Self.sendActivationEmail(req, email: email)
        return .ok
    }
    
    @discardableResult
    func activate(_ req: Request) async throws -> HTTPResponseStatus {
        guard let jwt = req.parameters.get("jwt") else { throw Abort(.badRequest, reason: "Please make sure the activation link is correct.") }
        // Throws 401 when fails.
        let payload = try await req.jwt.verify(jwt, as: UserJWT.self)
        
        guard payload.subject == UserJWT.Subject.activation else { throw Abort(.forbidden) }
        guard let idString = payload.audience.value.first, let id = UUID(uuidString: idString) else { throw Abort(.forbidden) }
        guard let user = try await User.find(id, on: req.db) else { throw Abort(.notFound, reason: "User does not exist") }
        user.activated = true
        try await user.save(on: req.db)
        // Login the user
        req.auth.login(user)
        req.session.authenticate(user)
        return .ok
    }
    
    func login(_ req: Request) async throws -> HTTPResponseStatus {
        // For auth header, api calls
        if req.headers.basicAuthorization != nil {
            let user = try req.auth.require(User.self)
            req.auth.login(user)
            req.session.authenticate(user)
            return .ok
        }
        
        // For content body, frontend, better error description.
        let loginInfo = try req.content.decode(User.LoginInput.self)
        guard let user = try await User.query(on: req.db).group(.or, { group in
            group.filter(\.$email == loginInfo.username)
            group.filter(\.$username == loginInfo.username)
        }).first() else {
            throw Abort(.forbidden, reason: "User not found")
        }
        guard try user.verify(password: loginInfo.password) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }
        req.session.authenticate(user)
        return .ok
    }
    
    func logout(_ req: Request) async throws -> HTTPResponseStatus {
        req.auth.logout(User.self)
        req.session.destroy()
        return .ok
    }
    
    func requestOTP(_ req: Request) async throws -> HTTPResponseStatus {
        let string = try req.content.decode(String.self)
        guard string.range(of: User.emailRegex, options: .regularExpression) != nil else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }
        guard let user = try await User.query(on: req.db).filter(\.$email == string).first() else {
            throw Abort(.unauthorized, reason: "Email address is not registered with \(req.application.configuration.siteName)")
        }
        let otp = try await user.genNewOTP(req)
        let content = try await req.render("/EmailTemplates/RequestOTP", EmailCtx(otp: otp))
        guard let text = content.data.getString(at: 0, length: content.data.readableBytes) else {
            throw Abort(.internalServerError, reason: "Unanble to get generate otp email content")
        }
        
        let mail = Mail(to: [.init(name: user.username, email: user.email)], subject: "One Time Password", contentType: .html, text: text)
        let _ = req.application.sendMail(mail)
        
        return .ok
    }
    
    func otpLogin(_ req: Request) async throws -> HTTPResponseStatus {
        struct OTPInfo: Codable {
            let email: String
            let otp: String
        }
        let otpInfo = try req.content.decode(OTPInfo.self)
        guard let user = try await User.query(on: req.db).filter(\.$email == otpInfo.email).with(\.$otps).first() else {
            throw Abort(.unauthorized)
        }
        
        guard let foundOTP = user.otps.filter({ $0.otp == otpInfo.otp }).first else {
            throw Abort(.unauthorized)
        }
        req.auth.login(user)
        req.session.authenticate(user)
        try await foundOTP.delete(on: req.db)
        return .ok
    }
    
    func requestPWChange(_ req: Request) async throws -> HTTPResponseStatus {
        struct Email: Codable {
            let email: String
        }
        let email = try req.content.decode(Email.self).email
        guard email.range(of: User.emailRegex, options: .regularExpression) != nil else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }
        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            throw Abort(.unauthorized, reason: "Email address is not registered with \(req.application.configuration.siteName)")
        }
        let host = try req.host
        let jwt = try await user.generateJWT(req, subject: UserJWT.Subject.changePW)
        let content = try await req.render("/EmailTemplates/RequestPWChange", EmailCtx(host: host, jwt: jwt))
        guard let text = content.data.getString(at: 0, length: content.data.readableBytes) else {
            throw Abort(.internalServerError, reason: "Un able to generate change password email content")
        }
        
        let mail = Mail(to: [.init(name: user.username, email: user.email)], subject: "Change Password for \(req.application.configuration.siteName)", contentType: .html, text: text)
        let _ = req.application.sendMail(mail)
        return .ok
    }
    
    func changePW(_ req: Request) async throws -> HTTPResponseStatus {
        struct ChangePWContent: Codable {
            let password1: String
            let password2: String
        }
        
        let content = try req.content.decode(ChangePWContent.self)
        guard content.password1 == content.password2 else {
            throw Abort(.badRequest, reason: "Passwords don't match")
        }
        guard User.passwordLength.contains(content.password1.count) else {
            throw Abort(.badRequest, reason: "Password must be at least \(User.passwordLength.lowerBound) characters and \(User.passwordLength.upperBound) at most.")
        }
        
        // changePW token is signed by user's password(before changing) in order to guarantee the token's one-time-use nature. So verify the jwt using app's default key will fail. Before verifying, we need to convert the parameter string to a jwt token, extract user id and get the old password first.
        guard let jwt = req.parameters.get("jwt"),
              // the DefaultJWTParser().parse() function needs a DataProtocol as paramter, so make sure the string can be converted to data first.
              let data = jwt.data(using: .utf8),
              let token = try? DefaultJWTParser().parse(data, as: UserJWT.self),
              token.payload.subject == UserJWT.Subject.changePW,
              let idString = token.payload.audience.value.first,
              let userID = UUID(uuidString: idString),
              let user = try await User.find(userID, on: req.db)
        else { throw Abort(.badRequest, reason: "Can't find user for the given email address") }
        
        let keyCollection = await JWTKeyCollection().add(hmac: .init(from: user.password), digestAlgorithm: .sha256)
        do {
            let _ = try await keyCollection.verify(jwt, as: UserJWT.self)
        } catch {
            throw Abort(.unauthorized, reason: "Link expired, please request a new link and use it within \(jwtValidMinutes) mins")
        }
        user.password = try Bcrypt.hash(content.password1)
        try await user.save(on: req.db)
        return .ok
    }
}


