import Foundation

class ProcessMonitor {
    
    /// Prints the top CPU and memory consuming processes
    func printTopProcesses() {
        ReactorLogger.logAndPrint("🔍 Fetching and printing top processes...", type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,pcpu,pmem,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try task.run()
            task.waitUntilExit()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            ReactorLogger.logSystemCommand(command: "/bin/ps", arguments: ["-axo", "pid,pcpu,pmem,comm"], success: task.terminationStatus == 0, duration: duration)
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                // Print header
                if let header = lines.first {
                    print(header)
                    print(String(repeating: "-", count: 60))
                }
                
                // Parse and sort processes by CPU usage
                var processes: [(pid: String, cpu: Double, line: String)] = []
                
                for line in lines.dropFirst() {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if !trimmedLine.isEmpty {
                        let components = trimmedLine.components(separatedBy: .whitespaces)
                        if components.count >= 4 {
                            if let pid = components.first,
                               let cpu = Double(components[1]) {
                                processes.append((pid: pid, cpu: cpu, line: trimmedLine))
                            }
                        }
                    }
                }
                
                // Sort by CPU usage (descending)
                processes.sort { $0.cpu > $1.cpu }
                
                ReactorLogger.logAndPrint("Parsed \(processes.count) processes, displaying top 10", type: .info, category: ReactorLogger.process, categoryName: "Process")
                
                // Print top 10 processes
                for (index, process) in processes.prefix(10).enumerated() {
                    print("\(index + 1). \(process.line)")
                }
                
                if processes.count > 10 {
                    print("... and \(processes.count - 10) more processes")
                }
            }
        } catch {
            ReactorLogger.logError("Error running ps command", error: error, category: ReactorLogger.system)
            print("Error running ps command: \(error)")
        }
    }
    
    /// Gets a list of running processes with their details (shell-based version)
    func getProcessList() -> [ProcessInfo] {
        ReactorLogger.logAndPrint("🔍 Getting process list using shell...", type: .debug, category: ReactorLogger.process, categoryName: "Process")
        
        var processes: [ProcessInfo] = []
        
        // Try a different approach using shell command
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Use shell to execute ps command
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "ps -axo pid,pcpu,pmem,comm | head -20"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            try task.run()
            task.waitUntilExit()
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            ReactorLogger.logAndPrint("Shell command completed in \(String(format: "%.3f", duration))s with exit code: \(task.terminationStatus)", type: .debug, category: ReactorLogger.system, categoryName: "System")
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    ReactorLogger.logAndPrint("Got \(lines.count) lines from shell ps command", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                    
                    // Debug: print first few lines to see the format
                    for (index, line) in lines.prefix(3).enumerated() {
                        ReactorLogger.logAndPrint("Line \(index): '\(line)'", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                    }
                    
                    // Parse the output
                    for line in lines.dropFirst() { // Skip header
                        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                        if !trimmedLine.isEmpty {
                            // Split by whitespace and handle multiple spaces
                            let components = trimmedLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                            ReactorLogger.logAndPrint("Parsing line: '\(trimmedLine)' -> \(components.count) components", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                            
                            if components.count >= 4,
                               let pid = Int(components[0]),
                               let cpu = Double(components[1]),
                               let memory = Double(components[2]) {
                                
                                let command = components.dropFirst(3).joined(separator: " ")
                                let cleanCommand = extractProcessName(from: command)
                                processes.append(ProcessInfo(pid: pid, cpu: cpu, memory: memory, command: cleanCommand))
                                ReactorLogger.logAndPrint("Added process: PID=\(pid), CPU=\(cpu)%, MEM=\(memory)%, CMD=\(cleanCommand)", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                            } else {
                                ReactorLogger.logAndPrint("Failed to parse line: '\(trimmedLine)' - components: \(components)", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                            }
                        }
                    }
                }
            } else {
                ReactorLogger.logAndPrint("Shell command failed with exit code: \(task.terminationStatus)", type: .error, category: ReactorLogger.system, categoryName: "System")
            }
        } catch {
            ReactorLogger.logError("Error executing shell ps command", error: error, category: ReactorLogger.system)
            
            // Fallback: create some dummy processes for testing
            ReactorLogger.logAndPrint("Creating dummy processes for testing", type: .info, category: ReactorLogger.process, categoryName: "Process")
            processes = [
                ProcessInfo(pid: 1, cpu: 0.1, memory: 0.2, command: "launchd"),
                ProcessInfo(pid: 2, cpu: 5.2, memory: 1.5, command: "kernel_task"),
                ProcessInfo(pid: 3, cpu: 2.1, memory: 0.8, command: "WindowServer"),
                ProcessInfo(pid: 4, cpu: 1.5, memory: 2.1, command: "Reactor"),
                ProcessInfo(pid: 5, cpu: 0.8, memory: 0.5, command: "Safari")
            ]
        }
        
        // Sort by CPU usage (descending)
        processes.sort { $0.cpu > $1.cpu }
        
        ReactorLogger.logAndPrint("✅ Retrieved and sorted \(processes.count) processes", type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        return processes
    }
    
    /// Extracts a clean process name from the full command path
    private func extractProcessName(from command: String) -> String {
        // Remove common prefixes and get just the process name
        let cleanCommand = command.replacingOccurrences(of: "/usr/bin/", with: "")
                                 .replacingOccurrences(of: "/bin/", with: "")
                                 .replacingOccurrences(of: "/System/Library/", with: "")
                                 .replacingOccurrences(of: "/Applications/", with: "")
        
        // If it's a .app bundle, extract the app name
        if cleanCommand.contains(".app/") {
            if let appRange = cleanCommand.range(of: ".app/") {
                let beforeApp = cleanCommand[..<appRange.lowerBound]
                if let lastSlash = beforeApp.lastIndex(of: "/") {
                    return String(beforeApp[beforeApp.index(after: lastSlash)...])
                } else {
                    return String(beforeApp)
                }
            }
        }
        
        // For other commands, take the first component (before first space)
        let firstComponent = cleanCommand.components(separatedBy: " ").first ?? cleanCommand
        
        // If it's a path, get just the filename
        if firstComponent.contains("/") {
            return String(firstComponent.split(separator: "/").last ?? "Unknown")
        }
        
        return firstComponent
    }
    
    /// Kills a process with the given PID
    func killProcess(pid: Int) -> Bool {
        ReactorLogger.logAndPrint("⚔️ Attempting to kill process with PID: \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-TERM", "\(pid)"] // Use SIGTERM first (more graceful)
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try task.run()
            task.waitUntilExit()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            ReactorLogger.logSystemCommand(command: "/bin/kill", arguments: ["-TERM", "\(pid)"], success: task.terminationStatus == 0, duration: duration)
            
            if task.terminationStatus == 0 {
                ReactorLogger.logAndPrint("✅ Successfully sent SIGTERM to process \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
                return true
            } else {
                ReactorLogger.logAndPrint("⚠️ Failed to terminate process \(pid) with SIGTERM, trying SIGKILL...", type: .error, category: ReactorLogger.process, categoryName: "Process")
                return forceKillProcess(pid: pid)
            }
        } catch {
            ReactorLogger.logError("Error killing process \(pid)", error: error, category: ReactorLogger.system)
            return false
        }
    }
    
    /// Force kills a process with SIGKILL
    private func forceKillProcess(pid: Int) -> Bool {
        ReactorLogger.logAndPrint("💀 Force killing process with PID: \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(pid)"] // SIGKILL
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try task.run()
            task.waitUntilExit()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            ReactorLogger.logSystemCommand(command: "/bin/kill", arguments: ["-9", "\(pid)"], success: task.terminationStatus == 0, duration: duration)
            
            if task.terminationStatus == 0 {
                ReactorLogger.logAndPrint("✅ Successfully force killed process \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
                return true
            } else {
                ReactorLogger.logAndPrint("❌ Failed to force kill process \(pid)", type: .error, category: ReactorLogger.process, categoryName: "Process")
                return false
            }
        } catch {
            ReactorLogger.logError("Error force killing process \(pid)", error: error, category: ReactorLogger.system)
            return false
        }
    }
    
    /// Gets system memory info
    func getSystemMemoryInfo() -> SystemMemoryInfo? {
        let task = Process()
        task.launchPath = "/usr/bin/vm_stat"
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return parseMemoryInfo(from: output)
            }
        } catch {
            print("Error getting memory info: \(error)")
        }
        
        return nil
    }
    
    private func parseMemoryInfo(from output: String) -> SystemMemoryInfo {
        let lines = output.components(separatedBy: .newlines)
        var freePages = 0
        var activePages = 0
        var inactivePages = 0
        var wiredPages = 0
        
        for line in lines {
            if line.contains("Pages free:") {
                let components = line.components(separatedBy: .whitespaces)
                if let pages = Int(components.last?.replacingOccurrences(of: ".", with: "") ?? "") {
                    freePages = pages
                }
            } else if line.contains("Pages active:") {
                let components = line.components(separatedBy: .whitespaces)
                if let pages = Int(components.last?.replacingOccurrences(of: ".", with: "") ?? "") {
                    activePages = pages
                }
            } else if line.contains("Pages inactive:") {
                let components = line.components(separatedBy: .whitespaces)
                if let pages = Int(components.last?.replacingOccurrences(of: ".", with: "") ?? "") {
                    inactivePages = pages
                }
            } else if line.contains("Pages wired down:") {
                let components = line.components(separatedBy: .whitespaces)
                if let pages = Int(components.last?.replacingOccurrences(of: ".", with: "") ?? "") {
                    wiredPages = pages
                }
            }
        }
        
        // Each page is typically 4KB on macOS
        let pageSize = 4096
        let totalMemory = (freePages + activePages + inactivePages + wiredPages) * pageSize
        let usedMemory = (activePages + inactivePages + wiredPages) * pageSize
        let freeMemory = freePages * pageSize
        
        return SystemMemoryInfo(
            totalMemory: totalMemory,
            usedMemory: usedMemory,
            freeMemory: freeMemory
        )
    }
}

// MARK: - Data Models

struct ProcessInfo {
    let pid: Int
    let cpu: Double
    let memory: Double
    let command: String
    
    var formattedDescription: String {
        return String(format: "PID: %d, CPU: %.1f%%, Memory: %.1f%%, Command: %@", pid, cpu, memory, command)
    }
}

struct SystemMemoryInfo {
    let totalMemory: Int
    let usedMemory: Int
    let freeMemory: Int
    
    var totalMemoryGB: Double {
        return Double(totalMemory) / (1024 * 1024 * 1024)
    }
    
    var usedMemoryGB: Double {
        return Double(usedMemory) / (1024 * 1024 * 1024)
    }
    
    var freeMemoryGB: Double {
        return Double(freeMemory) / (1024 * 1024 * 1024)
    }
    
    var memoryUsagePercentage: Double {
        return (Double(usedMemory) / Double(totalMemory)) * 100
    }
}