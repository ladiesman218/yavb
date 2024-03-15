import Vapor
import ConsoleKit
import Puppy

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        
        try configLogger(env: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.execute()
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
        let fileURL = URL(fileURLWithPath: "./yavb-logs/yavb.log").absoluteURL
        let rotationConfig = RotationConfig(suffixExtension: .date_uuid,
                                            maxFileSize: 5 * 1024 * 1024,
                                            maxArchivedFilesCount: 5)
        let fileRotation = try FileRotationLogger("top.douwone.yavb.persist",
                                                  logFormat: logFormat,
                                                  fileURL: fileURL,
                                                  rotationConfig: rotationConfig)
        var puppy = Puppy()
        puppy.add(fileRotation)
        // Puppy's add function requires loggers have different lables
        let console = ConsoleLogger("top.douwone.yavb.console", logFormat: logFormat)
        puppy.add(console)
        
        try LoggingSystem.bootstrap(from: &env) { level in
            return { label -> LogHandler in
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
