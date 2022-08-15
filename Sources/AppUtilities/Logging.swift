
import Foundation
import os
import SwiftUI

public final class Log {
}

#if DEBUG

public extension OSLog {
    func callAsFunction(_ type: OSLogType, _ s: String) {
        os_log("%{public}s", log: self, type: type, s)
    }
}

fileprivate final class LogContainer: ObservableObject {
    /// List of all log messages in chronological order.
    @Published var logs: [(String, String, String, Date)] = []
    
    /// Shared instance.
    static let shared: LogContainer = LogContainer()
    
    /// Default initializer.
    init() {}
}

public struct Logger {
    /// The logger subsystem.
    let subsystem: String
    
    /// The logger category.
    let category: String
    
    /// The OS logger.
    let logger: OSLog
    
    /// Default initializer.
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.logger = OSLog(subsystem: subsystem, category: category)
    }
    
    public func log(_ message: String) {
        LogContainer.shared.logs.append(("Log", category, message, Date()))
        logger(.default, message)
    }
    
    public func debug(_ message: String) {
        LogContainer.shared.logs.append(("Debug", category, message, Date()))
        logger(.debug, message)
    }
    
    public func info(_ message: String) {
        LogContainer.shared.logs.append(("Info", category, message, Date()))
        logger(.info, message)
    }
    
    public func notice(_ message: String) {
        LogContainer.shared.logs.append(("Notice", category, message, Date()))
        logger(.default, message)
    }
    
    public func warning(_ message: String) {
        LogContainer.shared.logs.append(("Warning", category, message, Date()))
        logger(.default, message)
    }
    
    public func error(_ message: String) {
        LogContainer.shared.logs.append(("Error", category, message, Date()))
        logger(.error, message)
    }
    
    public func critical(_ message: String, submitAnalytics: Bool = false) {
        var message = message
        message += """
            \n------------------------------
            [Stack Trace]
            \(Thread.callStackSymbols.joined(separator: "\n"))
            ------------------------------
        """
        
        LogContainer.shared.logs.append(("Critical", category, message, Date()))
        logger(.fault, message)
    }
    
    public func temporary(_ message: String) {
        LogContainer.shared.logs.append(("Debug", category, message, Date()))
        logger(.debug, message)
    }
}

extension DefaultStringInterpolation {
    public mutating func appendInterpolation<T>(_ argumentObject: @autoclosure @escaping () -> T,
                                                privacy: OSLogPrivacy)
    where T: CustomStringConvertible
    {
        self.appendInterpolation(argumentObject().description)
    }
}

internal struct LogsView: View {
    /// The log container.
    @ObservedObject fileprivate var container: LogContainer = .shared
    
    /// Get the color for a log type.
    func color(for logType: String) -> Color? {
        switch logType {
        case "Debug":
            return Color.blue
        case "Error":
            return Color.red
        case "Critical":
            return Color.red
        case "Warning":
            return Color.yellow
        default:
            return nil
        }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach((0..<container.logs.count).reversed(), id: \.self) { i in
                let log = container.logs[i]
                Text(verbatim: "[\(Format.formatDateTime(log.3))][\(log.0)][\(log.1)]")
                    .font(.body.monospacedDigit())
                    .foregroundColor(self.color(for: log.0))
                    .opacity(0.75)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(verbatim: log.2)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }
}

#else

extension Logger {
    /// Discard a debug log.
    func debug(_ message: String) {
        
    }
    
    /// Log a critical error that should be submitted as Analytics.
    func critical(_ message: String, submitAnalytics: Bool) {
        os_log("%{public}s", type: .fault, message)
        
        if submitAnalytics {
            var message = message
            message += """
                \n------------------------------
                [Stack Trace]
                \(Thread.callStackSymbols.joined(separator: "\n"))
                ------------------------------
            """
        }
    }
}

#endif
