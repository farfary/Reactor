import Foundation
import AppKit

/// Service responsible for classifying processes into appropriate types and categories (standards-based, minimal heuristics)
class ProcessClassifier {
    private let introspection = ProcessIntrospection.shared

    // MARK: - Main Classification Method
    func classifyProcess(command: String, fullPath: String, pid: Int) -> ProcessType {
        let lcCommand = command.lowercased()
        let path = fullPath.isEmpty ? (introspection.executablePath(for: pid) ?? command) : fullPath
        let lcPath = path.lowercased()

        // Kernel
        if pid == 0 || lcCommand == "kernel_task" || lcCommand.contains(" kernel") {
            return .kernel
        }

        // Try NSRunningApplication for application detection
        if let ra = introspection.runningApplication(for: pid) {
            switch ra.activationPolicy {
            case .regular:
                // UI apps
                return isSystemBundle(path) ? .systemApplication : .userApplication
            case .accessory:
                // UI agents (menu bar extras, helpers) – treat as background tasks
                return .backgroundTask
            case .prohibited:
                // Non-UI background processes; keep checking launchctl to decide daemon vs background
                break
            @unknown default:
                break
            }
        }

        // If executable is within an .app bundle, it's an application
        if isWithinAppBundle(path) {
            return isSystemBundle(path) ? .systemApplication : .userApplication
        }

        // launchctl info can reveal LaunchAgents/LaunchDaemons
        if let info = introspection.launchctlInfo(for: pid) {
            if let plistPath = info.path?.lowercased() {
                if plistPath.contains("/launchdaemons/") {
                    return .systemDaemon
                }
                if plistPath.contains("/launchagents/") {
                    // Agents run on behalf of a user and may interact with GUI
                    return .userDaemon
                }
            }
            // If type indicates user and not in agents, lean towards user daemon
            if let type = info.type?.lowercased(), type.contains("user") {
                return .userDaemon
            }
        }

        // Path-based minimal rules for typical daemon locations
        if lcPath.hasPrefix("/system/library/") || lcPath.hasPrefix("/usr/libexec/") || lcPath.hasPrefix("/usr/sbin/") {
            return .systemDaemon
        }
        if lcPath.contains("/library/launchagents/") {
            return .userDaemon
        }

        // Background helpers (non-UI helpers not tied to launchd plist)
        if lcCommand.contains("helper") || lcCommand.contains("service") || lcCommand.contains("agent") {
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
        return appBundlePath(from: path) != nil
    }

    private func appBundlePath(from path: String) -> String? {
        guard let range = path.range(of: ".app", options: [.caseInsensitive]) else { return nil }
        let end = range.upperBound
        let bundlePath = String(path[..<end])
        return bundlePath
    }

    private func isSystemBundle(_ path: String) -> Bool {
        let lp = path.lowercased()
        return lp.hasPrefix("/system/applications/") || lp.contains("/system/library/coreservices/") || lp.contains("/applications/utilities/")
    }
}