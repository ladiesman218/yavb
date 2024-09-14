import Vapor
import Fluent
import FluentPostgresDriver
import SMTPKitten
import Fakery

struct Install: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let installRoutes = routes.grouped("install")
        installRoutes.get(use: renderInstall)
        installRoutes.post(use: registerWebmaster)
        installRoutes.get("import", use: renderImport)
        installRoutes.post("import", use: importDummyData)
        installRoutes.get("finished", use: renderFinished)
        installRoutes.grouped(User.sessionAuthenticator()).get("test", use: test)
    }
    
    static func testDBConnection(_ req: Request) async throws {
        guard let dbHost = Environment.get("DATABASE_HOST"),
              let dbName = Environment.get("DATABASE_NAME"),
              let dbPort = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)),
              let dbUser = Environment.get("DATABASE_USERNAME"),
              let dbPass = Environment.get("DATABASE_PASSWORD") else {
            throw Abort(.badRequest, reason: "Missing database info")
        }
        let conf = PostgresConnection.Configuration(host: dbHost, port: dbPort, username: dbUser, password: dbPass, database: dbName, tls: .disable)
        
        let connection = try await PostgresConnection.connect(configuration: conf, id: 1, logger: req.logger)
        try await connection.close()
    }
    
    static func testSMTPConnection(_ req: Request) async throws {
        guard let smtpServer = Environment.get("SMTP_SERVER"),
              let smtpAccount = Environment.get("SMTP_ACCOUNT"),
              let smtpPass = Environment.get("SMTP_PASSWORD") else {
            throw Abort(.badRequest, reason: "Missing smtp info")
        }
        
        let client = try await SMTPClient.connect(hostname: smtpServer, port: 587, ssl: .startTLS(configuration: .default)).get()
        try await client.login(user: smtpAccount, password: smtpPass).get()
    }
    
    func renderInstall(_ req: Request) async throws -> View {
        guard try await User.query(on: req.db).filter(\User.$role == .webmaster).count() == 0 else {
            return try await req.render("/SetupGuide/finished", EmptyCtx())
        }
        return try await req.render("/SetupGuide/install", EmptyCtx())
    }
    
    func registerWebmaster(_ req: Request) async throws -> HTTPResponseStatus {
        guard try await User.query(on: req.db).filter(\User.$role == .webmaster).count() == 0 else {
            throw Abort(.forbidden, reason: "Webmaster already exists")
        }
        
        let input = try req.content.decode(User.RegisterInput.self)
        let user = try await input.makeUser(req: req)
        user.role = .webmaster
        user.activated = true
        try await user.save(on: req.db)
        webmasterExists = true
        return .created
    }
    
    func renderImport(_ req: Request) async throws -> Response {
        guard req.application.environment == .development else {
            if try await User.query(on: req.db).filter(\.$role == .webmaster).count() == 0 {
                return req.redirect(to: "/install")
            }
            return req.redirect(to: "/install/finished")
        }
        return try await req.render("/SetupGuide/import", EmptyCtx()).encodeResponse(for: req)
    }
    
    func importDummyData(_ req: Request) async throws -> HTTPResponseStatus {
        guard req.application.environment == .development else {
            throw Abort(.badRequest)
        }
        struct Numbers: Codable {
            let usersCount: Int
            let postsCount: Int
            let commentsCount: Int
        }
        let numbers = try req.content.decode(Numbers.self)
        try await Self.importDummyData(req, usersCount: numbers.usersCount, postsCount: numbers.postsCount, commentsCount: numbers.commentsCount)
        return .ok
    }
    
    func renderFinished(_ req: Request) async throws -> View {
        return try await req.render("/SetupGuide/finished", EmptyCtx())
    }
    
    static func importDummyData(_ req: Request, usersCount: Int, postsCount: Int, commentsCount: Int) async throws {
        
        guard let webmaster = try await User.query(on: req.db).filter(\.$role == .webmaster).first() else {
            throw Abort(.imATeapot, reason: "A webmaster must exist before you can generate fake user in db")
        }
        
        guard try await BlogPost.query(on: req.db).filter(\.$type == .post).count() == 0 else {
            throw Abort(.imATeapot, reason: "DB not empty")
        }
        
        let registerTime = Date(timeIntervalSinceNow: -1 * 60 * 60 * 24 * 365)
        webmaster.registerTime = registerTime
        try await webmaster.save(on: req.db)
        
        let faker = Faker()
        
        var allUsers: [User] = []
        var allPosts: [BlogPost] = []
        
        req.logger.info("Generating dummy data for db ...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate users
        while allUsers.count < usersCount {
            let username = faker.internet.username()
            let email = faker.internet.email()
            if allUsers.allSatisfy({
                $0.username != username && $0.email != email
            }) {
                // 20% of un-activated users vs 80% of activated
                let activated = (Int.random(in: 1...10) >= 3 ? true : false)
                let role: User.Role
                if activated {
                    let number = Int.random(in: 1...100)
                    // 10% of admin, 30% of author, 60% of subscriber
                    switch number {
                        case 1...13:
                            role = .admin
                        case 14...52:
                            role = .author
                        default:
                            role = .subscriber
                    }
                } else {
                    role = .subscriber
                }
                let user = try User(username: username, email: email, password: faker.internet.password(), activated: activated, role: role)
                allUsers.append(user)
            }
        }
        
        if !allUsers.isEmpty && allUsers.filter({$0.activated}).isEmpty {
            allUsers.first!.activated = true
        }
        let usersGenerationEnd = CFAbsoluteTimeGetCurrent()
        req.logger.info("Took \(usersGenerationEnd - startTime) seconds to generate \(allUsers.count) users...")
        
        // Save users in db
        try await withThrowingTaskGroup(of: Void.self) { group in
            for user in allUsers {
                try await user.save(on: req.db)
                user.registerTime = faker.date.between(registerTime, Date.now)
                try await user.save(on: req.db)
            }
        }
        let usersSavingEnd = CFAbsoluteTimeGetCurrent()
        let activatedUsers = allUsers.filter { $0.activated }
        let authors = activatedUsers.filter { $0.role == .author || $0.role == .admin }
        req.logger.info("Took \(usersSavingEnd - usersGenerationEnd) seconds to save \(allUsers.count) users, \(activatedUsers.count) of which are activated")
        
        // Generate BlogPosts
        while allPosts.count < postsCount {
            let title = faker.lorem.words(amount: Int.random(in: 2...6))
            let content = faker.lorem.paragraphs(amount: Int.random(in: 3...10))
            if allPosts.allSatisfy({
                $0.title != title && $0.content != content
            }) {
                let user = authors.randomElement() ?? webmaster
                let number = Int.random(in: 1...100)
                let status: BlogPost.Status
                // 15% of draft, 40% of published, 30% of pendingReview, 15% of rejected
                switch number {
                    case 1...15:
                        status = .draft
                    case 16...55:
                        status = .published
                    case 56...85:
                        status = .pendingReview
                    default:
                        status = .rejected
                }
                let post = BlogPost(title: title, excerpt: faker.lorem.sentence(wordsAmount: Int.random(in: 20...50)), content: content, authorID: try user.requireID(), type: .post, status: status)
                allPosts.append(post)
            }
        }
        
        // Save posts in db
        let postsGeneration = CFAbsoluteTimeGetCurrent()
        req.logger.info("Took \(postsGeneration  - usersSavingEnd) seconds to generate \(allPosts.count) posts...")
        try await withThrowingTaskGroup(of: Void.self) { group in
            for post in allPosts {
                try await post.save(on: req.db)
                let authorRegisterTime = try await post.$author.get(on: req.db).registerTime!
                let createTime = faker.date.between(authorRegisterTime, Date.now)
                post.createdAt = createTime
                post.updatedAt = createTime
                try await post.save(on: req.db)
            }
        }
        let postsSavingEnd = CFAbsoluteTimeGetCurrent()
        let publishedPosts = allPosts.filter { $0.status == .published }
        req.logger.info("Took \(postsSavingEnd - postsGeneration) seconds to save \(allPosts.count) posts, \(publishedPosts.count) of which are published")
        
        // Generate Comment data
        guard !publishedPosts.isEmpty else { return }
        for _ in 0 ..< commentsCount {
            if let userID = try activatedUsers.randomElement()?.requireID(), let post = publishedPosts.randomElement() {
                let comment = Comment(userID: userID, postID: try post.requireID(), content: faker.lorem.sentence(wordsAmount: Int.random(in: 5...30)), status: faker.number.randomBool())
                try await comment.save(on: req.db)
            }
        }
        let commentsGenerationEnd = CFAbsoluteTimeGetCurrent()
        req.logger.info("Took \(commentsGenerationEnd - postsSavingEnd) seconds to generate and save 10000 comments ")
        req.logger.info("Data seeding completed.")
    }
    func test(_ req: Request) async throws -> Response {
        let a = SQLQueryString("")
        
//        print(webmasterExists)
//        req.application.middleware = .init()
//        req.application.middleware.use(MyRouteLoggingMiddleware())
//        req.application.middleware.use(ErrorMiddleware.default(environment: req.application.environment))
//        print(req.application.middleware.resolve())
//        try restartApp(req)
//        req.application.asyncCommands.use(Cowsay(), as: "cowsay")
//        let a = HelloCommand()
//        a.use()
//        context.console.print("Hello 👋")
        return .init()
    }
}
