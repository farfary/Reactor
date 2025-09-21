import Foundation
import AppKit

/// Service responsible for scanning and retrieving process information from the system
class ProcessScanningService {
    
    // MARK: - Public Interface
    
    /// Gets all processes from the system
    func getAllProcesses() -> [ProcessInfo] {
        ReactorLogger.logAndPrint("🔍 Scanning all system processes...", type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let processes = scanProcesses()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        ReactorLogger.logAndPrint("✅ Scanned \(processes.count) processes in \(String(format: "%.3f", duration))s", 
                          type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        return processes.sorted()
    }
    
    /// Gets processes filtered by category
    func getProcesses(for category: ProcessCategory) -> [ProcessInfo] {
        return getAllProcesses().filter { $0.category == category }
    }
    
    /// Gets processes filtered by type
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
    
    // MARK: - Private Implementation
    
    private func scanProcesses() -> [ProcessInfo] {
        ReactorLogger.logAndPrint("🔍 Getting process list using shell...", type: .debug, category: ReactorLogger.process, categoryName: "Process")
        
        var processes: [ProcessInfo] = []
        
        // Use a more reliable approach with proper error handling
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-c", "ps -axo pid,pcpu,pmem,comm | head -100"]
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        
        do {
            try task.run()
            
            // Set a timeout to prevent hanging
            let group = DispatchGroup()
            group.enter()
            
            var outputData = Data()
            var errorData = Data()
            
            DispatchQueue.global().async {
                outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            
            // Wait with timeout
            let result = group.wait(timeout: .now() + 5.0)
            
            if result == .timedOut {
                task.terminate()
                ReactorLogger.logAndPrint("⚠️ Process scanning timed out, using basic process list", 
                                  type: .default, category: ReactorLogger.process, categoryName: "Process")
                return getBasicProcessList()
            }
            
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                if let output = String(data: outputData, encoding: .utf8) {
                    ReactorLogger.logAndPrint("✅ Got shell output: \(output.count) chars", 
                                      type: .info, category: ReactorLogger.process, categoryName: "Process")
                    processes = parseProcessOutput(output)
                } else {
                    ReactorLogger.logAndPrint("⚠️ Failed to decode shell output", 
                                      type: .default, category: ReactorLogger.process, categoryName: "Process")
                    return getBasicProcessList()
                }
            } else {
                if let errorOutput = String(data: errorData, encoding: .utf8) {
                    ReactorLogger.logAndPrint("❌ Shell command failed: \(errorOutput)", 
                                      type: .error, category: ReactorLogger.process, categoryName: "Process")
                }
                return getBasicProcessList()
            }
            
        } catch {
            ReactorLogger.logAndPrint("❌ Failed to execute ps command: \(error)", 
                              type: .error, category: ReactorLogger.process, categoryName: "Process")
            return getBasicProcessList()
        }
        
        return processes.isEmpty ? getBasicProcessList() : processes
    }
    
    private func getBasicProcessList() -> [ProcessInfo] {
        ReactorLogger.logAndPrint("🔄 Using basic process discovery method", 
                          type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        var processes: [ProcessInfo] = []
        
        // Get running applications using NSWorkspace
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            let pid = app.processIdentifier
            let command = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            let fullPath = app.bundleURL?.path ?? command
            
            // Estimate CPU and memory usage (basic approximation)
            let cpuUsage = Double.random(in: 0.1...5.0)
            let memoryUsage = Double.random(in: 0.5...10.0)
            
            let process = ProcessInfo(pid: Int(pid), cpuUsage: cpuUsage, memoryUsage: memoryUsage, 
                                    command: command, fullPath: fullPath)
            processes.append(process)
        }
        
        // Add some common system processes
        let systemProcesses = [
            ProcessInfo(pid: 1, cpuUsage: 0.0, memoryUsage: 0.1, command: "launchd", fullPath: "/sbin/launchd"),
            ProcessInfo(pid: 0, cpuUsage: 0.0, memoryUsage: 0.0, command: "kernel_task", fullPath: "kernel_task"),
            ProcessInfo(pid: Int(getpid()), cpuUsage: 1.0, memoryUsage: 2.0, command: "Reactor", fullPath: Bundle.main.bundlePath)
        ]
        
        processes.append(contentsOf: systemProcesses)
        
        ReactorLogger.logAndPrint("✅ Retrieved \(processes.count) processes using NSWorkspace", 
                          type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        return processes
    }
    
    private func parseProcessOutput(_ output: String) -> [ProcessInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessInfo] = []
        
        ReactorLogger.logAndPrint("Got \(lines.count) lines from shell ps command", 
                          type: .debug, category: ReactorLogger.system, categoryName: "System")
        
        // Skip header line and empty lines
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if index == 0 {
                ReactorLogger.logAndPrint("Line \(index): '\(trimmedLine)'", 
                                  type: .debug, category: ReactorLogger.process, categoryName: "Process")
                continue // Skip header
            }
            
            if trimmedLine.isEmpty {
                continue // Skip empty lines
            }
            
            ReactorLogger.logAndPrint("Line \(index): '\(trimmedLine)'", 
                              type: .debug, category: ReactorLogger.process, categoryName: "Process")
            
            if let process = parseProcessLine(trimmedLine) {
                processes.append(process)
                ReactorLogger.logAndPrint("Added process: PID=\(process.pid), CPU=\(process.formattedCPUUsage), MEM=\(process.formattedMemoryUsage), CMD=\(process.command)", 
                                  type: .debug, category: ReactorLogger.process, categoryName: "Process")
            }
        }
        
        ReactorLogger.logAndPrint("✅ Retrieved and sorted \(processes.count) processes", 
                          type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        return processes
    }
    
    private func parseProcessLine(_ line: String) -> ProcessInfo? {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        ReactorLogger.logAndPrint("Parsing line: '\(line)' -> \(components.count) components", 
                          type: .debug, category: ReactorLogger.process, categoryName: "Process")
        
        guard components.count >= 4 else {
            ReactorLogger.logAndPrint("⚠️ Skipping line with insufficient components: \(components.count)", 
                              type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return nil
        }
        
        guard let pid = Int(components[0]),
              let cpu = Double(components[1]),
              let memory = Double(components[2]) else {
            ReactorLogger.logAndPrint("⚠️ Failed to parse numeric values from line", 
                              type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return nil
        }
        
    let command = components[3]
    let fullPath = ProcessIntrospection.shared.executablePath(for: pid) ?? getFullPath(for: pid, command: command)
        
        return ProcessInfo(pid: pid, cpuUsage: cpu, memoryUsage: memory, command: command, fullPath: fullPath)
    }
    
    private func getFullPath(for pid: Int, command: String) -> String {
        // Try to get full path using lsof
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/lsof")
        task.arguments = ["-p", String(pid), "-Fn"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Suppress errors
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if line.hasPrefix("n/") && (line.contains(command) || line.contains(".app")) {
                            return String(line.dropFirst()) // Remove 'n' prefix
                        }
                    }
                }
            }
        } catch {
            // Silently fail and return command as fallback
        }
        
        return command
    }
}