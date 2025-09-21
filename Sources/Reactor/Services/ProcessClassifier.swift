import Foundation
import AppKit

/// Service responsible for classifying processes into appropriate types and categories
class ProcessClassifier {
    
    // MARK: - System Application Patterns
    private let systemApplicationPaths = [
        "/System/Applications/",
        "/System/Library/CoreServices/",
        "/Applications/Utilities/"
    ]
    
    // MARK: - User Application Patterns
    private let userApplicationPaths = [
        "/Applications/",
        "/Users/*/Applications/"
    ]
    
    // MARK: - System Daemon Patterns
    private let systemDaemonPatterns = [
        "launchd", "kernel_task", "kextd", "mds", "mdworker",
        "cfprefsd", "distnoted", "notifyd", "syslogd", "powerd",
        "coreauthd", "securityd", "trustd", "locationd", "bluetoothd",
        "wifivelocityd", "networkd", "airportd", "configd", "discoveryd",
        "systemstats", "thermalmonitord", "logd", "smd", "amfid",
        "keybagd", "softwareupdated", "watchdogd", "iconservicesd",
        "fseventsd", "mediaremoted", "accessoryupdaterd", "uarpassetmanagerd",
        "endpointsecurityd", "corespeechd_system"
    ]
    
    // MARK: - Background Task Patterns
    private let backgroundTaskPatterns = [
        "com.apple.", "Safari ", "Chrome ", "Firefox ", "TextEdit ",
        "mdworker", "Spotlight", "backupd", "TimeMachine", 
        "cloudpaird", "cloudd", "syncdefaultsd"
    ]
    
    // MARK: - User Daemon Patterns
    private let userDaemonPatterns = [
        "UserEventAgent", "cfprefsd", "distnoted", "pboard",
        "loginwindow", "Dock", "SystemUIServer", "Finder",
        "WindowServer", "Control Center"
    ]
    
    // MARK: - Main Classification Method
    func classifyProcess(command: String, fullPath: String, pid: Int) -> ProcessType {
        let lowercaseCommand = command.lowercased()
        let lowercasePath = fullPath.lowercased()
        
        // Special case for kernel processes
        if pid == 0 || lowercaseCommand.contains("kernel") || lowercaseCommand == "kernel_task" {
            return .kernel
        }
        
        // Check if it's a user application
        if isUserApplication(command: command, fullPath: fullPath) {
            return .userApplication
        }
        
        // Check if it's a system application
        if isSystemApplication(command: command, fullPath: fullPath) {
            return .systemApplication
        }
        
        // Check if it's a system daemon
        if isSystemDaemon(command: command, fullPath: fullPath) {
            return .systemDaemon
        }
        
        // Check if it's a user daemon
        if isUserDaemon(command: command, fullPath: fullPath) {
            return .userDaemon
        }
        
        // Check if it's a background task
        if isBackgroundTask(command: command, fullPath: fullPath) {
            return .backgroundTask
        }
        
        return .unknown
    }
    
    // MARK: - Category Assignment
    func categorizeProcess(type: ProcessType) -> ProcessCategory {
        switch type {
        case .userApplication, .systemApplication:
            return .applications
        case .systemDaemon:
            return .systemServices
        case .backgroundTask:
            return .backgroundProcesses
        case .userDaemon:
            return .daemons
        case .kernel:
            return .kernelProcesses
        case .unknown:
            return .backgroundProcesses // Default category
        }
    }
    
    // MARK: - Application Detection
    func isApplication(command: String, fullPath: String) -> Bool {
        return isUserApplication(command: command, fullPath: fullPath) ||
               isSystemApplication(command: command, fullPath: fullPath)
    }
    
    // MARK: - Bundle Identifier Extraction
    func getBundleIdentifier(fullPath: String) -> String? {
        if fullPath.contains(".app") {
            // Extract .app bundle path
            if let appRange = fullPath.range(of: ".app") {
                let appPath = String(fullPath[...appRange.upperBound])
                let cleanAppPath = appPath.replacingOccurrences(of: ".app/", with: ".app")
                
                // Try to read bundle identifier from Info.plist
                let infoPlistPath = "\(cleanAppPath)/Contents/Info.plist"
                if FileManager.default.fileExists(atPath: infoPlistPath),
                   let plistData = NSDictionary(contentsOfFile: infoPlistPath),
                   let bundleId = plistData["CFBundleIdentifier"] as? String {
                    return bundleId
                }
            }
        }
        return nil
    }
    
    // MARK: - Private Classification Methods
    
    private func isUserApplication(command: String, fullPath: String) -> Bool {
        // Check if path indicates user application
        for path in userApplicationPaths {
            if fullPath.hasPrefix(path) && fullPath.contains(".app") {
                return true
            }
        }
        
        // Check for .app extension in path
        if fullPath.contains(".app/") || fullPath.hasSuffix(".app") {
            // Exclude system applications
            return !isSystemApplication(command: command, fullPath: fullPath)
        }
        
        return false
    }
    
    private func isSystemApplication(command: String, fullPath: String) -> Bool {
        // Check if path indicates system application
        for path in systemApplicationPaths {
            if fullPath.hasPrefix(path) {
                return true
            }
        }
        
        // Check for specific system app patterns
        if fullPath.contains(".app") && (fullPath.contains("/System/") || fullPath.contains("CoreServices")) {
            return true
        }
        
        return false
    }
    
    private func isSystemDaemon(command: String, fullPath: String) -> Bool {
        let lowercaseCommand = command.lowercased()
        
        // Check against known system daemon patterns
        for pattern in systemDaemonPatterns {
            if lowercaseCommand.contains(pattern.lowercased()) {
                return true
            }
        }
        
        // Check path patterns
        if fullPath.hasPrefix("/usr/libexec/") || 
           fullPath.hasPrefix("/System/Library/") ||
           fullPath.hasPrefix("/usr/sbin/") {
            return true
        }
        
        // Check for 'd' suffix (daemon convention)
        if lowercaseCommand.hasSuffix("d") && 
           (fullPath.contains("/System/") || fullPath.contains("/usr/")) {
            return true
        }
        
        return false
    }
    
    private func isUserDaemon(command: String, fullPath: String) -> Bool {
        let lowercaseCommand = command.lowercased()
        
        // Check against known user daemon patterns
        for pattern in userDaemonPatterns {
            if command.contains(pattern) || lowercaseCommand.contains(pattern.lowercased()) {
                return true
            }
        }
        
        // Check for user-specific paths
        if fullPath.contains("/Users/") && !fullPath.contains(".app") {
            return true
        }
        
        return false
    }
    
    private func isBackgroundTask(command: String, fullPath: String) -> Bool {
        // Check against known background task patterns
        for pattern in backgroundTaskPatterns {
            if command.contains(pattern) {
                return true
            }
        }
        
        // Check for background service indicators
        if command.contains("Background") || 
           command.contains("Helper") ||
           command.contains("Service") {
            return true
        }
        
        return false
    }
}