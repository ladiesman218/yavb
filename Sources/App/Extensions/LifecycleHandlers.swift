import Vapor
import Fluent

struct LoadSiteSettings: LifecycleHandler {
    func didBootAsync(_ application: Application) async throws {
        async let count = try? User.query(on: application.db).filter(\.$role == .webmaster).count()
                
        let fileManager = FileManager.default
        let configPath = application.directory.workingDirectory + "config.\(application.environment.name).json"
        
        var isDir: ObjCBool = .init(true)
        guard (fileManager.fileExists(atPath: configPath, isDirectory: &isDir) && !isDir.boolValue) || fileManager.createFile(atPath: configPath, contents: nil) else {
            throw Abort(.internalServerError, reason: "Unable to create file at \(configPath)")
        }
        
        guard fileManager.isReadableFile(atPath: configPath) && fileManager.isWritableFile(atPath: configPath) else {
            throw Abort(.internalServerError, reason: "No read/write permission for file: \(configPath)")
        }
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)), let config = try? JSONDecoder().decode(Configuration.self, from: data) {
            application.configuration = config
        } else {
            application.configuration = Configuration.default(for: application.environment)
        }
        
        webmasterExists =  await (count == 1) ? true : false
    }
}

extension Application {
    private struct ConfigurationKey: StorageKey {
        typealias Value = Configuration
    }
    
    var configuration: Configuration {
        get {
            self.storage[ConfigurationKey.self] ?? Configuration.default(for: self.environment)
        }
        set {
            self.storage[ConfigurationKey.self] = newValue
            self.saveConfigurationToFile(newValue)
        }
    }
    
    private func saveConfigurationToFile(_ config: Configuration) {
        let fileManager = FileManager.default
        let configPath = self.directory.workingDirectory + "config.\(self.environment.name).json"
        
        do {
            let data = try JSONEncoder().encode(config)
            if fileManager.isWritableFile(atPath: configPath) {
                try data.write(to: URL(fileURLWithPath: configPath))
            } else {
                throw Abort(.internalServerError, reason: "No write permission for configuration file.")
            }
        } catch {
            self.logger.error("Failed to save configuration: \(error)")
        }
    }
    
}

struct Configuration: Codable {
    var allowRegistration: Bool
    var allowGuestPost: Bool
    var allowComment: Bool
    var commentNeedReview: Bool
    var postsNeedReview: Bool
    var siteName: String
    
    static func `default`(for environment: Environment) -> Self {
        return Self.init(
            allowRegistration: false,
            allowGuestPost: false,
            allowComment: false,
            commentNeedReview: true,
            postsNeedReview: true,
            siteName: "Yet Another Vapor Blog"
        )
    }
}
