import Foundation
import AppKit

/// Enhanced process information model
struct ProcessInfo {
    let pid: Int
    let cpuUsage: Double
    let memoryUsage: Double
    let command: String
    let fullPath: String
    let processType: ProcessType
    let category: ProcessCategory
    let isApplication: Bool
    let bundleIdentifier: String?
    let startTime: Date?
    let parentPID: Int?
    let user: String?
    
    /// Initialize with basic process data
    init(pid: Int, cpuUsage: Double, memoryUsage: Double, command: String, fullPath: String = "") {
        self.pid = pid
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.command = command
        self.fullPath = fullPath.isEmpty ? command : fullPath
        
        // Classify the process
        let classifier = ProcessClassifier()
        self.processType = classifier.classifyProcess(command: command, fullPath: self.fullPath, pid: pid)
        self.category = classifier.categorizeProcess(type: self.processType)
        self.isApplication = classifier.isApplication(command: command, fullPath: self.fullPath)
        self.bundleIdentifier = classifier.getBundleIdentifier(fullPath: self.fullPath)
        
        // Additional metadata (would be populated by enhanced process scanning)
        self.startTime = nil
        self.parentPID = nil
        self.user = nil
    }
    
    /// Rebuild a ProcessInfo using cached metadata but new CPU/Memory metrics
    init(meta: ProcessInfo, cpuUsage: Double, memoryUsage: Double) {
        self.pid = meta.pid
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.command = meta.command
        self.fullPath = meta.fullPath
        self.processType = meta.processType
        self.category = meta.category
        self.isApplication = meta.isApplication
        self.bundleIdentifier = meta.bundleIdentifier
        self.startTime = meta.startTime
        self.parentPID = meta.parentPID
        self.user = meta.user
    }

    /// Enhanced initializer with full metadata
    init(pid: Int, cpuUsage: Double, memoryUsage: Double, command: String, fullPath: String, 
         startTime: Date?, parentPID: Int?, user: String?) {
        self.pid = pid
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.command = command
        self.fullPath = fullPath
        self.startTime = startTime
        self.parentPID = parentPID
        self.user = user
        
        // Classify the process
        let classifier = ProcessClassifier()
        self.processType = classifier.classifyProcess(command: command, fullPath: fullPath, pid: pid)
        self.category = classifier.categorizeProcess(type: self.processType)
        self.isApplication = classifier.isApplication(command: command, fullPath: fullPath)
        self.bundleIdentifier = classifier.getBundleIdentifier(fullPath: fullPath)
    }
    
    /// Display name for the process (cleaned up command name or app name)
    var displayName: String {
        if isApplication, let bundleIdentifier = bundleIdentifier {
            // Try to get the app name from the bundle path
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
               let bundle = Bundle(url: url),
               let appName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                            bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                            bundle.localizedInfoDictionary?["CFBundleName"] as? String ??
                            bundle.infoDictionary?["CFBundleName"] as? String {
                return appName
            }
        }
        
        // Fall back to cleaned command name
        return command.components(separatedBy: "/").last ?? command
    }
    
    /// Detailed description for tooltips
    var detailedDescription: String {
        var description = "Process: \(displayName)\n"
        description += "PID: \(pid)\n"
        description += "Type: \(processType.rawValue)\n"
        description += "CPU: \(String(format: "%.1f", cpuUsage))%\n"
        description += "Memory: \(String(format: "%.1f", memoryUsage))%\n"
        
        if !fullPath.isEmpty && fullPath != command {
            description += "Path: \(fullPath)\n"
        }
        
        if let bundleId = bundleIdentifier {
            description += "Bundle: \(bundleId)\n"
        }
        
        if let user = user {
            description += "User: \(user)\n"
        }
        
        if let parentPID = parentPID {
            description += "Parent PID: \(parentPID)\n"
        }
        
        return description
    }
    
    /// Memory usage in human-readable format
    var formattedMemoryUsage: String {
        return String(format: "%.1f%%", memoryUsage)
    }
    
    /// CPU usage in human-readable format
    var formattedCPUUsage: String {
        return String(format: "%.1f%%", cpuUsage)
    }
}

// MARK: - Comparable for sorting
extension ProcessInfo: Comparable {
    static func < (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        // First sort by category priority
        if lhs.category.displayPriority != rhs.category.displayPriority {
            return lhs.category.displayPriority < rhs.category.displayPriority
        }
        
        // Then by process type priority
        if lhs.processType.displayPriority != rhs.processType.displayPriority {
            return lhs.processType.displayPriority < rhs.processType.displayPriority
        }
        
        // Finally by CPU usage (descending)
        return lhs.cpuUsage > rhs.cpuUsage
    }
    
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        return lhs.pid == rhs.pid
    }
}

// MARK: - Hashable for use in collections
extension ProcessInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
}