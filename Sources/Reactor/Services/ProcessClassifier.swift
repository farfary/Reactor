import Foundation
import AppKit

/// Service responsible for classifying processes into appropriate types and categories (standards-based, minimal heuristics)
class ProcessClassifier {
    private let introspection = ProcessIntrospection.shared

    // MARK: - Main Classification Method
    func classifyProcess(command: String, fullPath: String, pid: Int) -> ProcessType {
        let lcCommand = command.lowercased()
        let execPath = introspection.executablePath(for: pid)
        let pathForClass = execPath ?? (fullPath.isEmpty ? command : fullPath)
        let lcPath = pathForClass.lowercased()

        // Kernel
        if pid == 0 || lcCommand == "kernel_task" || lcCommand.contains(" kernel") {
            return .kernel
        }

        // Try NSRunningApplication for application detection
        if let ra = introspection.runningApplication(for: pid) {
            switch ra.activationPolicy {
            case .regular:
                // UI apps
                let t: ProcessType = isSystemBundle(pathForClass) ? .systemApplication : .userApplication
                ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as \(t.rawValue) via activationPolicy=regular", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                return t
            case .accessory:
                // UI agents (menu bar extras, helpers) – treat as background tasks
                ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as Background Task via activationPolicy=accessory", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                return .backgroundTask
            case .prohibited:
                // Non-UI background processes; keep checking launchctl to decide daemon vs background
                break
            @unknown default:
                break
            }
        }

        // If executable is within an .app bundle, it's an application
        if isWithinAppBundle(pathForClass) {
            // Special-case: loginwindow is a system app bundle
            if lcPath.contains("/system/library/coreservices/loginwindow.app/") {
                ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as System Application (loginwindow)", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                return .systemApplication
            }
            let t: ProcessType = isSystemBundle(pathForClass) ? .systemApplication : .userApplication
            ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as \(t.rawValue) via .app bundle path", type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return t
        }

        // launchctl info can reveal LaunchAgents/LaunchDaemons
        if let info = introspection.launchctlInfo(for: pid) {
            if let plistPath = info.path?.lowercased() {
                if plistPath.contains("/launchdaemons/") {
                    ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as System Daemon via launchctl path", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                    return .systemDaemon
                }
                if plistPath.contains("/launchagents/") {
                    // Agents run on behalf of a user and may interact with GUI
                    ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as User Daemon via launchctl path", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                    return .userDaemon
                }
            }
            // If type indicates user and not in agents, lean towards user daemon
            if let type = info.type?.lowercased(), type.contains("user") {
                ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as User Daemon via launchctl type=user", type: .debug, category: ReactorLogger.process, categoryName: "Process")
                return .userDaemon
            }
        }

        // Path-based minimal rules for typical daemon locations
        if lcPath.hasPrefix("/system/library/") || lcPath.hasPrefix("/usr/libexec/") || lcPath.hasPrefix("/usr/sbin/") || lcPath.hasPrefix("/sbin/") {
            ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as System Daemon via path", type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return .systemDaemon
        }
        if lcPath.contains("/library/launchagents/") {
            ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as User Daemon via path", type: .debug, category: ReactorLogger.process, categoryName: "Process")
            return .userDaemon
        }

        // Background helpers (non-UI helpers not tied to launchd plist)
        if lcCommand.contains("helper") || lcCommand.contains("service") || lcCommand.contains("agent") {
            ReactorLogger.logAndPrint("✅ Classify PID=\(pid) as Background Task via name markers", type: .debug, category: ReactorLogger.process, categoryName: "Process")
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
            return .backgroundProcesses
        }
    }

    // MARK: - Application Detection
    func isApplication(command: String, fullPath: String) -> Bool {
        let path = !fullPath.isEmpty ? fullPath : command
        return isWithinAppBundle(path)
    }

    // MARK: - Bundle Identifier Extraction
    func getBundleIdentifier(fullPath: String) -> String? {
        let path = fullPath
        guard let appPath = appBundlePath(from: path) else { return nil }
        let infoPlistPath = "\(appPath)/Contents/Info.plist"
        if FileManager.default.fileExists(atPath: infoPlistPath),
           let plistData = NSDictionary(contentsOfFile: infoPlistPath),
           let bundleId = plistData["CFBundleIdentifier"] as? String {
            return bundleId
        }
        return nil
    }

    // MARK: - Helpers
    private func isWithinAppBundle(_ path: String) -> Bool {
        guard let appPath = appBundlePath(from: path) else { return false }
        // Verify executable lies under <bundle>/Contents/MacOS/
        if let macOSRange = path.range(of: "/Contents/MacOS/", options: [.caseInsensitive]) {
            let prefix = String(path[..<macOSRange.upperBound])
            if prefix.lowercased().hasPrefix(appPath.lowercased()) {
                return true
            }
        }
        // Fallback: ensure Info.plist exists to treat as bundle
        let infoPlist = "\(appPath)/Contents/Info.plist"
        return FileManager.default.fileExists(atPath: infoPlist)
    }

    private func appBundlePath(from path: String) -> String? {
        // Require .app followed by Contents to avoid false positives from lsof
        guard let appRange = path.range(of: ".app/Contents", options: [.caseInsensitive]) else { return nil }
        let end = appRange.lowerBound
    let bundlePath = String(path[..<end])
        if !bundlePath.lowercased().hasSuffix(".app") { return nil }
        return bundlePath
    }

    private func isSystemBundle(_ path: String) -> Bool {
        let lp = path.lowercased()
        return lp.hasPrefix("/system/applications/") || lp.contains("/system/library/coreservices/") || lp.contains("/applications/utilities/")
    }
}