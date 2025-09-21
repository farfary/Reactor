import Foundation

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
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,pcpu,pmem,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        var processes: [ProcessInfo] = []
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try task.run()
            task.waitUntilExit()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            let success = task.terminationStatus == 0
            ReactorLogger.logSystemCommand(command: "/bin/ps", arguments: task.arguments ?? [], success: success, duration: duration)
            
            if success {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    processes = parseProcessOutput(output)
                }
            } else {
                ReactorLogger.logAndPrint("❌ ps command failed with exit code \(task.terminationStatus)", 
                                  type: .error, category: ReactorLogger.process, categoryName: "Process")
            }
            
        } catch {
            ReactorLogger.logAndPrint("❌ Failed to execute ps command: \(error)", 
                              type: .error, category: ReactorLogger.process, categoryName: "Process")
        }
        
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
        let fullPath = getFullPath(for: pid, command: command)
        
        return ProcessInfo(pid: pid, cpuUsage: cpu, memoryUsage: memory, command: command, fullPath: fullPath)
    }
    
    private func getFullPath(for pid: Int, command: String) -> String {
        // Try to get full path using lsof
        let task = Process()
        task.launchPath = "/usr/bin/lsof"
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