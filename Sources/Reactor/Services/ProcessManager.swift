import Foundation

import Foundation
import AppKit
import os.log

/// Central manager for all process-related operations
class ProcessManager {
    
    // MARK: - Services
    private let scanningService = ProcessScanningService()
    private let iconService = ProcessIconService()
    private let classifier = ProcessClassifier()
    
    // MARK: - Cache
    private var cachedProcesses: [ProcessInfo] = []
    private var lastUpdateTime: Date = Date.distantPast
    private let cacheTimeout: TimeInterval = 5.0 // 5 seconds
    
    // MARK: - Public Interface
    
    /// Gets all processes, using cache if available and recent
    func getAllProcesses(forceRefresh: Bool = false) -> [ProcessInfo] {
        if !forceRefresh && shouldUseCache() {
            ReactorLogger.logAndPrint("📋 Using cached process list (\(cachedProcesses.count) processes)", 
                                     type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return cachedProcesses
        }
        
        ReactorLogger.logAndPrint("🔄 Refreshing process list...", 
                                 type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let processes = scanningService.getAllProcesses()
        updateCache(with: processes)
        
        // Preload icons in background
        iconService.preloadIcons(for: Array(processes.prefix(20))) // Top 20 processes
        
        return processes
    }
    
    /// Gets processes organized by category
    func getProcessesByCategory() -> [ProcessCategory: [ProcessInfo]] {
        let allProcesses = getAllProcesses()
        var categorizedProcesses: [ProcessCategory: [ProcessInfo]] = [:]
        
        for category in ProcessCategory.allCases {
            categorizedProcesses[category] = allProcesses.filter { $0.category == category }
        }
        
        return categorizedProcesses
    }
    
    /// Gets processes for a specific category
    func getProcesses(for category: ProcessCategory) -> [ProcessInfo] {
        return getAllProcesses().filter { $0.category == category }
    }
    
    /// Gets processes of a specific type
    func getProcesses(of type: ProcessType) -> [ProcessInfo] {
        return getAllProcesses().filter { $0.processType == type }
    }
    
    /// Gets top processes by CPU usage
    func getTopProcessesByCPU(limit: Int = 10) -> [ProcessInfo] {
        return getAllProcesses()
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Gets top processes by memory usage
    func getTopProcessesByMemory(limit: Int = 10) -> [ProcessInfo] {
        return getAllProcesses()
            .sorted { $0.memoryUsage > $1.memoryUsage }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Gets the icon for a specific process
    func getIcon(for process: ProcessInfo) -> NSImage? {
        return iconService.getIcon(for: process)
    }
    
    /// Attempts to terminate a process
    func killProcess(pid: Int) -> Bool {
        ReactorLogger.logAndPrint("⚔️ Attempting to terminate process PID: \(pid)", 
                                 type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-TERM", String(pid)]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let success = task.terminationStatus == 0
            
            if success {
                ReactorLogger.logAndPrint("✅ Successfully sent TERM signal to PID: \(pid)", 
                                         type: .info, category: ReactorLogger.process, categoryName: "Process")
                
                // Force refresh cache after kill
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    _ = self.getAllProcesses(forceRefresh: true)
                }
            } else {
                ReactorLogger.logAndPrint("❌ Failed to terminate PID: \(pid) (exit code: \(task.terminationStatus))", 
                                         type: .error, category: ReactorLogger.process, categoryName: "Process")
            }
            
            return success
            
        } catch {
            ReactorLogger.logAndPrint("❌ Exception while terminating PID: \(pid) - \(error)", 
                                     type: .error, category: ReactorLogger.process, categoryName: "Process")
            return false
        }
    }
    
    /// Forces termination of a process (SIGKILL)
    func forceKillProcess(pid: Int) -> Bool {
        ReactorLogger.logAndPrint("💀 Force terminating process PID: \(pid)", 
                                 type: .fault, category: ReactorLogger.process, categoryName: "Process")
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-KILL", String(pid)]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let success = task.terminationStatus == 0
            
            if success {
                ReactorLogger.logAndPrint("✅ Successfully force killed PID: \(pid)", 
                                         type: .info, category: ReactorLogger.process, categoryName: "Process")
                
                // Force refresh cache after kill
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    _ = self.getAllProcesses(forceRefresh: true)
                }
            } else {
                ReactorLogger.logAndPrint("❌ Failed to force kill PID: \(pid) (exit code: \(task.terminationStatus))", 
                                         type: .error, category: ReactorLogger.process, categoryName: "Process")
            }
            
            return success
            
        } catch {
            ReactorLogger.logAndPrint("❌ Exception while force killing PID: \(pid) - \(error)", 
                                     type: .error, category: ReactorLogger.process, categoryName: "Process")
            return false
        }
    }
    
    /// Gets system resource information
    func getSystemInfo() -> SystemInfo {
        return SystemInfo()
    }
    
    /// Clears all caches
    func clearCaches() {
        cachedProcesses.removeAll()
        lastUpdateTime = Date.distantPast
        iconService.clearCache()
        
        ReactorLogger.logAndPrint("🧹 Cleared all process caches", 
                                 type: .info, category: ReactorLogger.process, categoryName: "Process")
    }
    
    // MARK: - Private Methods
    
    private func shouldUseCache() -> Bool {
        return Date().timeIntervalSince(lastUpdateTime) < cacheTimeout && !cachedProcesses.isEmpty
    }
    
    private func updateCache(with processes: [ProcessInfo]) {
        cachedProcesses = processes
        lastUpdateTime = Date()
    }
}

// MARK: - System Information Model
struct SystemInfo {
    let totalMemory: UInt64
    let usedMemory: UInt64
    let cpuUsage: Double
    let processCount: Int
    
    init() {
        // Get memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let task = mach_task_self_
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            self.usedMemory = UInt64(info.resident_size)
        } else {
            self.usedMemory = 0
        }
        
        // Get total physical memory
        var size = UInt64(0)
        var len = size_t(MemoryLayout<UInt64>.size)
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        self.totalMemory = size
        
        // CPU usage calculation would require more complex implementation
        // For now, using a placeholder
        self.cpuUsage = 0.0
        
        // Process count from current cache or scan
        self.processCount = 0
    }
    
    var memoryUsagePercentage: Double {
        guard totalMemory > 0 else { return 0.0 }
        return Double(usedMemory) / Double(totalMemory) * 100.0
    }
    
    var formattedMemoryUsage: String {
        return String(format: "%.1f%%", memoryUsagePercentage)
    }
    
    var formattedTotalMemory: String {
        return ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory)
    }
    
    var formattedUsedMemory: String {
        return ByteCountFormatter.string(fromByteCount: Int64(usedMemory), countStyle: .memory)
    }
}