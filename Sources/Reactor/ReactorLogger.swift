import Foundation
import os.log

/// Reactor Logger - Standard macOS logging system using os.log
class ReactorLogger {
    
    // MARK: - Logging Categories
    
    /// Application lifecycle and general events
    static let app = OSLog(subsystem: "com.reactor.app", category: "Application")
    
    /// Menubar and UI related events
    static let ui = OSLog(subsystem: "com.reactor.app", category: "UserInterface")
    
    /// Process monitoring and management
    static let process = OSLog(subsystem: "com.reactor.app", category: "ProcessMonitor")
    
    /// System interactions and commands
    static let system = OSLog(subsystem: "com.reactor.app", category: "System")
    
    /// Performance and debugging
    static let performance = OSLog(subsystem: "com.reactor.app", category: "Performance")
    
    // MARK: - Convenience Logging Methods
    
    /// Log application lifecycle events
    static func logApp(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: app, type: type, message)
    }
    
    /// Log UI and menubar events
    static func logUI(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: ui, type: type, message)
    }
    
    /// Log process monitoring events
    static func logProcess(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: process, type: type, message)
    }
    
    /// Log system command execution
    static func logSystem(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: system, type: type, message)
    }
    
    /// Log performance metrics
    static func logPerformance(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: performance, type: type, message)
    }
    
    // MARK: - Specialized Logging Methods
    
    /// Log errors with detailed context
    static func logError(_ message: String, error: Error? = nil, category: OSLog = app) {
        if let error = error {
            os_log("%{public}@ - Error: %{public}@", log: category, type: .error, message, error.localizedDescription)
        } else {
            os_log("%{public}@", log: category, type: .error, message)
        }
    }
    
    /// Log debugging information (only in debug builds)
    static func logDebug(_ message: String, category: OSLog = app) {
        #if DEBUG
        os_log("%{public}@", log: category, type: .debug, message)
        #endif
    }
    
    /// Log info messages
    static func logInfo(_ message: String, category: OSLog = app) {
        os_log("%{public}@", log: category, type: .info, message)
    }
    
    /// Log fault conditions
    static func logFault(_ message: String, category: OSLog = app) {
        os_log("%{public}@", log: category, type: .fault, message)
    }
    
    // MARK: - Process-specific Logging
    
    /// Log process monitoring start
    static func logProcessMonitoringStart() {
        logProcess("Starting process monitoring", type: .info)
    }
    
    /// Log process list retrieval
    static func logProcessListRetrieval(count: Int, duration: TimeInterval) {
        logProcess("Retrieved \(count) processes in \(String(format: "%.3f", duration))s", type: .info)
    }
    
    /// Log process termination attempt
    static func logProcessTermination(pid: Int, processName: String, success: Bool) {
        if success {
            logProcess("Successfully terminated process: \(processName) (PID: \(pid))", type: .info)
        } else {
            logProcess("Failed to terminate process: \(processName) (PID: \(pid))", type: .error)
        }
    }
    
    // MARK: - UI-specific Logging
    
    /// Log menubar setup
    static func logMenubarSetup(success: Bool) {
        if success {
            logUI("Menubar status item created successfully", type: .info)
        } else {
            logUI("Failed to create menubar status item", type: .error)
        }
    }
    
    /// Log menu construction
    static func logMenuConstruction(itemCount: Int) {
        logUI("Constructed menu with \(itemCount) items", type: .debug)
    }
    
    /// Log menu interaction
    static func logMenuInteraction(action: String) {
        logUI("Menu interaction: \(action)", type: .debug)
    }
    
    // MARK: - System Command Logging
    
    /// Log system command execution
    static func logSystemCommand(command: String, arguments: [String], success: Bool, duration: TimeInterval) {
        let argString = arguments.joined(separator: " ")
        let fullCommand = "\(command) \(argString)"
        
        if success {
            logSystem("Command executed successfully: \(fullCommand) (\(String(format: "%.3f", duration))s)", type: .info)
        } else {
            logSystem("Command failed: \(fullCommand) (\(String(format: "%.3f", duration))s)", type: .error)
        }
    }
}

// MARK: - Console Logging Extensions

extension ReactorLogger {
    
    /// Also print to console for development (in addition to os.log)
    static func consolePrint(_ message: String, category: String = "Reactor") {
        print("[\(category)] \(message)")
    }
    
    /// Combined os.log and console logging for development
    static func logAndPrint(_ message: String, type: OSLogType = .default, category: OSLog = app, categoryName: String = "Reactor") {
        os_log("%{public}@", log: category, type: type, message)
        consolePrint(message, category: categoryName)
    }
}