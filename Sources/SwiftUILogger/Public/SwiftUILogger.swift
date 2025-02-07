import SwiftUI

///
open class SwiftUILogger: ObservableObject {
    ///
    public enum Level: Int {
        case success, debug, info, warning, error, fatal
        
        var color: Color {
            switch self {
            case .success: return .green
            case .debug: return Color(UIColor.brown)
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .red
            case .fatal: return .purple
            }
        }
        
        var emoji: Character {
            switch self {
            case .success: return "🟢"
            case .debug: return "🟤"
            case .info: return "🔵"
            case .warning: return "🟡"
            case .error: return "🔴"
            case .fatal: return "🟣"
            }
        }
    }
    
    ///
    public struct Event: Identifiable {
        public struct Metadata {
            public let file: StaticString
            public let line: Int
            public let tags: [any LogTagging]
            
            public init(
                file: StaticString,
                line: Int,
                tags: [any LogTagging]
            ) {
                self.file = file
                self.line = line
                self.tags = tags
            }
        }
        
        static let dateFormatter: DateFormatter = {
            var formatter = DateFormatter()
            
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            
            return formatter
        }()
        
        static let timeFormatter: DateFormatter = {
            var formatter = DateFormatter()
            
            formatter.timeStyle = .long
            formatter.dateStyle = .none
            
            return formatter
        }()
        
        ///
        public let id: UUID
        
        ///
        public let dateCreated: Date
        
        ///
        public let level: Level
        
        ///
        public let message: String
        
        ///
        public let error: Error?
        
        ///
        public let metadata: Metadata
        
        ///
        public init(
            level: Level,
            message: String,
            error: Error? = nil,
            tags: [any LogTagging] = [],
            _ file: StaticString = #fileID,
            _ line: Int = #line
        ) {
            self.id = UUID()
            self.dateCreated = Date()
            self.level = level
            self.message = message
            self.error = error
            self.metadata = .init(
                file: file,
                line: line,
                tags: tags
            )
        }
    }
    
    ///
    public static var `default`: SwiftUILogger = SwiftUILogger()
    
    private var lock: NSLock
    
    ///
    public let name: String?
    
    ///
    @Published public var logs: [Event]
    
    ///
    open var blob: String {
        lock.lock()
        defer { lock.unlock() }
        
        return logs
            .map { (event) -> String in
                let date = Event.dateFormatter.string(from: event.dateCreated)
                let time = Event.timeFormatter.string(from: event.dateCreated)
                let emoji = event.level.emoji.description
                let eventMessage = "\(date) \(time) \(emoji): \(event.message) (File: \(event.metadata.file)@\(event.metadata.line))"
                
                guard let error = event.error else {
                    return eventMessage
                }
                
                return eventMessage + "(Error: \(error.localizedDescription))"
            }
            .joined(separator: "\n")
    }
    
    ///
    public init(
        name: String? = nil,
        logs: [Event] = []
    ) {
        self.lock = NSLock()
        self.name = name
        self.logs = logs
    }
    
    ///
    open func log(
        level: Level,
        message: String,
        error: Error? = nil,
        tags: [any LogTagging] = [],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async {
                self.log(level: level, message: message, error: error, tags: tags, file, line)
            }
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        logs.append(
            Event(
                level: level,
                message: message,
                error: error,
                tags: tags,
                file,
                line
            )
        )
    }
    
    ///
    open func success(
        message: String,
        tags: [any LogTagging],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .success,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func info(
        message: String,
        tags: [any LogTagging],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .info,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func warning(
        message: String,
        tags: [any LogTagging],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .warning,
            message: message,
            error: nil,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func error(
        message: String,
        error: Error?,
        tags: [any LogTagging],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .error,
            message: message,
            error: error,
            tags: tags,
            file,
            line
        )
    }
    
    ///
    open func fatal(
        message: String,
        error: Error?,
        tags: [any LogTagging],
        _ file: StaticString = #fileID,
        _ line: Int = #line
    ) {
        log(
            level: .fatal,
            message: message,
            error: error,
            tags: tags,
            file,
            line
        )
    }
}
