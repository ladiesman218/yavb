import Vapor
import Fluent

final class ProtectedTagController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let protectedRoute = routes.grouped(User.credentialsAuthenticator(), User.sessionAuthenticator(), User.guardMiddleware()).grouped("api", "tag")
        protectedRoute.post("create", use: addTag)
        protectedRoute.post("update", ":old", ":new", use: updateTag)
        protectedRoute.post("delete", use: removeTag)
    }
    
    func addTag(_ req: Request) async throws -> Response {
        let strings = try req.content.decode([String].self)
        try await Self.add(tagNames: strings, database: req.db)
        return .init()
    }
    
    func removeTag(_ req: Request) async throws -> Response {
        let string = try req.content.decode(String.self)
        guard let tag = try await Tag.query(on: req.db).filter(\.$name == string).first() else { throw Abort(.notFound, reason: "Can't find the given tag") }
        try await tag.delete(on: req.db)
        return .init()
    }
    
    func updateTag(_ req: Request) async throws -> Response {
        guard let oldValue = req.parameters.get("old"),
              let newValue = req.parameters.get("new"),
              !newValue.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw Abort(.badRequest) }
        
        let existingTags = try await Tag.query(on: req.db).all()
        let (otherTags, trueElements) = existingTags.partitioned { $0.name == oldValue }
        guard let tag = trueElements.first else { throw Abort(.notFound) }
        guard !otherTags.compactMap({ $0.name }).contains(newValue) else { throw Abort(.conflict) }
        tag.name = newValue
        try await tag.save(on: req.db)
        
        return .init()
    }
    
    static func add(tagNames: [String], database: Database) async throws {
        // Filter out the ones that's not purely spaces/tabs, etc, those input will simply be ignored.
        let validNames = tagNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validNames.isEmpty else { return }
        
        // Query all tags, convert the names to strings and store them in an array.
        let existingTags = try await Tag.query(on: database).all().compactMap { $0.name }
        // Filter out all of the strings in the tags parameter that isn't in the existingTags array.
        let unsaved = validNames.filter { !existingTags.contains($0) }
        // Make sure unsaved tags can be saved, that is, the saved ones' lowercased version won't be exactly match the unsaved ones' lowercased version.
        guard Self.checkForConflict(unsaved: unsaved, saved: existingTags) else {
            throw Abort(.conflict, reason: "Similar tags already been saved")
        }
        guard !unsaved.isEmpty else { return }
        let tags = unsaved.map { Tag(name: $0) }
        
        try await withThrowingTaskGroup(of: Void.self) { group -> Void in
            tags.forEach { tag in
                group.addTask { try await tag.save(on: database) }
            }
            try Task.checkCancellation()
            guard !group.isCancelled else { return }
            try await group.waitForAll()
        }
    }
    
    static func checkForConflict(unsaved: [String], saved: [String]) -> Bool {
        let lowercased = unsaved.map { $0.lowercased()}
        let savedLowercased = saved.map { $0.lowercased() }
        guard !savedLowercased.contains(where: lowercased.contains) else {
            return false
        }
        return true
    }
    static func getTags(_ names: [String], req: Request) async throws -> [Tag] {
        return []
    }
}
