import Vapor
import ConsoleKit
import Puppy

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
//        env = .testing
        try configLogger(env: &env)
        
        let app = try await Application.make(env)
        
        do {
            try await configure(app)
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
    }
}

extension Entrypoint {
    static func configLogger(env: inout Environment) throws {
        // Implementations provided by swift-log
//        let level = try Logger.Level.detect(from: &env)
//        let label = "top.douwone.yavb"
//        let terminalLogger = ConsoleFragmentLogger(fragment: timestampDefaultLoggerFragment(), label: label, console: Terminal(), level: level, metadata: [:])
//        
//                var handlers: MultiplexLogHandler
//                if let string = Environment.get("PERSIST_LOGS"), let persistantLogs = Bool(string) {
//                    // Optionally create a persitant logger, which stores log messages in a file
//        //            let persistantLogger =
//                    handlers = MultiplexLogHandler([
//                        terminalLogger,
//                    ])
//                } else {
//                    handlers = MultiplexLogHandler([
//                        terminalLogger
//                    ])
//                }
//                LoggingSystem.bootstrap { label in handlers }
        
        // Implementations provided by Puppy
        let logFormat = LogFormatter()
        let logPath = "./logs/yavb.log"
        let fileURL = URL(fileURLWithPath: logPath).absoluteURL
        let rotationConfig = RotationConfig(suffixExtension: .numbering,
                                            maxFileSize: 5 * 1024 * 1024,
                                            maxArchivedFilesCount: 5)
        let fileRotation = try FileRotationLogger("top.douwone.yavb.persist",
                                                  logFormat: logFormat,
                                                  fileURL: fileURL,
                                                  rotationConfig: rotationConfig)
        
        try LoggingSystem.bootstrap(from: &env) { level in
            return { label -> LogHandler in
                var puppy = Puppy()
                puppy.add(fileRotation)
                // Puppy's add function requires loggers have different lables
                let console = ConsoleLogger("top.douwone.yavb.console", logFormat: logFormat)
                puppy.add(console)
                var handler = PuppyLogHandler(label: label, puppy: puppy)
                handler.logLevel = level
                return handler
            }
        }
    }
}

struct LogFormatter: LogFormattable {
    private let dateFormat = DateFormatter()
    
    init() {
        dateFormat.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
    }
    
    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
                       file: String, line: UInt, swiftLogInfo: [String : String],
                       label: String, date: Date, threadID: UInt64) -> String {
        let date = dateFormatter(date, withFormatter: dateFormat)
        return "[\(date)] [\(level.emoji) \(level)] \(swiftLogInfo["metadata"] ?? "") \(message)"
    }
}
