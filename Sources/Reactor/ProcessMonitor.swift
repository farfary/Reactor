import Foundation

class ProcessMonitor {
    
    /// Prints the top CPU and memory consuming processes
    func printTopProcesses() {
        print("Fetching top processes...")
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,pcpu,pmem,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
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
                
                // Print top 10 processes
                for (index, process) in processes.prefix(10).enumerated() {
                    print("\(index + 1). \(process.line)")
                }
                
                if processes.count > 10 {
                    print("... and \(processes.count - 10) more processes")
                }
            }
        } catch {
            print("Error running ps command: \(error)")
        }
    }
    
    /// Gets a list of running processes with their details
    func getProcessList() -> [ProcessInfo] {
        var processes: [ProcessInfo] = []
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,pcpu,pmem,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                // Skip header and parse processes
                for line in lines.dropFirst() {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if !trimmedLine.isEmpty {
                        // Use regex or more careful parsing since ps output can have varying spaces
                        let pattern = #"^\s*(\d+)\s+([\d.]+)\s+([\d.]+)\s+(.+)$"#
                        if let regex = try? NSRegularExpression(pattern: pattern) {
                            let nsString = trimmedLine as NSString
                            if let match = regex.firstMatch(in: trimmedLine, range: NSRange(location: 0, length: nsString.length)) {
                                if let pidRange = Range(match.range(at: 1), in: trimmedLine),
                                   let cpuRange = Range(match.range(at: 2), in: trimmedLine),
                                   let memRange = Range(match.range(at: 3), in: trimmedLine),
                                   let commRange = Range(match.range(at: 4), in: trimmedLine) {
                                    
                                    if let pid = Int(String(trimmedLine[pidRange])),
                                       let cpu = Double(String(trimmedLine[cpuRange])),
                                       let memory = Double(String(trimmedLine[memRange])) {
                                        let command = String(trimmedLine[commRange])
                                        let cleanCommand = extractProcessName(from: command)
                                        processes.append(ProcessInfo(pid: pid, cpu: cpu, memory: memory, command: cleanCommand))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error getting process list: \(error)")
        }
        
        // Sort by CPU usage (descending)
        processes.sort { $0.cpu > $1.cpu }
        
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
        print("Attempting to kill process with PID: \(pid)")
        
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-TERM", "\(pid)"] // Use SIGTERM first (more graceful)
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("Successfully sent SIGTERM to process \(pid)")
                return true
            } else {
                print("Failed to terminate process \(pid) with SIGTERM, trying SIGKILL...")
                return forceKillProcess(pid: pid)
            }
        } catch {
            print("Error killing process \(pid): \(error)")
            return false
        }
    }
    
    /// Force kills a process with SIGKILL
    private func forceKillProcess(pid: Int) -> Bool {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(pid)"] // SIGKILL
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("Successfully force killed process \(pid)")
                return true
            } else {
                print("Failed to force kill process \(pid)")
                return false
            }
        } catch {
            print("Error force killing process \(pid): \(error)")
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