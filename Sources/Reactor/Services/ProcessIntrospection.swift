import Foundation
import AppKit
import Darwin

/// Lightweight helpers to introspect processes by PID using system APIs and safe fallbacks
final class ProcessIntrospection {
    static let shared = ProcessIntrospection()

    private init() {}

    // MARK: - Caching
    private var raCache: [Int: NSRunningApplication?] = [:]
    private var pathCache: [Int: String?] = [:]
    private var launchctlCache: [Int: LaunchctlInfo?] = [:]
    private let cacheQueue = DispatchQueue(label: "reactor.process.introspection.cache", attributes: .concurrent)

    struct LaunchctlInfo {
        let type: String?      // e.g., System, User
        let path: String?      // path to the job's plist (LaunchAgents/LaunchDaemons)
        let userID: String?    // e.g., 501
    }

    // MARK: - Running Application
    func runningApplication(for pid: Int) -> NSRunningApplication? {
        if let cached = cacheQueue.sync(execute: { raCache[pid] }) {
            return cached
        }
        let app = NSRunningApplication(processIdentifier: pid_t(pid))
        cacheQueue.async(flags: .barrier) { self.raCache[pid] = app }
        return app
    }

    // MARK: - Executable Path (proc_pidpath with fallback)
    func executablePath(for pid: Int) -> String? {
    if let cached = cacheQueue.sync(execute: { pathCache[pid] }) { return cached }

        let bufSize = 4096 // typical maximum for proc_pidpath
        var buffer = Array<CChar>(repeating: 0, count: bufSize)
        let result = buffer.withUnsafeMutableBufferPointer { ptr -> Int32 in
            return proc_pidpath(Int32(pid), ptr.baseAddress, UInt32(bufSize))
        }

        if result > 0 {
            let path = String(cString: buffer)
            cacheQueue.async(flags: .barrier) { self.pathCache[pid] = path }
            return path
        }

        // Fallback: lsof -p <pid> -Fn (best effort, timeout handled by caller when needed)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/lsof")
        task.arguments = ["-p", String(pid), "-Fn"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    for line in output.components(separatedBy: .newlines) {
                        if line.hasPrefix("n/") {
                            let p = String(line.dropFirst())
                            if !p.isEmpty {
                                self.cacheQueue.async(flags: .barrier) { self.pathCache[pid] = p }
                                return p
                            }
                        }
                    }
                }
            }
        } catch {
            // ignore; will return nil
        }

        cacheQueue.async(flags: .barrier) { self.pathCache[pid] = nil }
        return nil
    }

    // MARK: - Launchctl Info (best-effort, parsed minimally)
    func launchctlInfo(for pid: Int, timeout: TimeInterval = 1.0) -> LaunchctlInfo? {
    if let cached = cacheQueue.sync(execute: { launchctlCache[pid] }) { return cached }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "launchctl print pid/\(pid) 2>/dev/null"]
        let out = Pipe()
        let err = Pipe()
        task.standardOutput = out
        task.standardError = err

        let group = DispatchGroup()
        group.enter()
        var outputData = Data()
        DispatchQueue.global().async {
            outputData = out.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        do { try task.run() } catch {
            cacheQueue.async(flags: .barrier) { self.launchctlCache[pid] = nil }
            return nil
        }

        let waitResult = group.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            task.terminate()
            cacheQueue.async(flags: .barrier) { self.launchctlCache[pid] = nil }
            return nil
        }
        task.waitUntilExit()

        guard task.terminationStatus == 0, let text = String(data: outputData, encoding: .utf8) else {
            cacheQueue.async(flags: .barrier) { self.launchctlCache[pid] = nil }
            return nil
        }

        var type: String?
        var path: String?
        var userID: String?

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("type = ") {
                type = trimmed.replacingOccurrences(of: "type = ", with: "")
            } else if trimmed.hasPrefix("path = ") {
                // path to job plist
                path = trimmed.replacingOccurrences(of: "path = ", with: "")
            } else if trimmed.hasPrefix("uid = ") {
                userID = trimmed.replacingOccurrences(of: "uid = ", with: "")
            }
        }

        let info = LaunchctlInfo(type: type, path: path, userID: userID)
        cacheQueue.async(flags: .barrier) { self.launchctlCache[pid] = info }
        return info
    }
}
