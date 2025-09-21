import Foundation
import AppKit

/// Service responsible for retrieving and managing process icons
class ProcessIconService {
    
    private var iconCache: [String: NSImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.reactor.icon-cache", attributes: .concurrent)
    
    // MARK: - Public Interface
    
    /// Gets the appropriate icon for a process
    func getIcon(for process: ProcessInfo) -> NSImage? {
        let cacheKey = "\(process.pid)-\(process.command)"
        
        // Check cache first
        if let cachedIcon = getCachedIcon(for: cacheKey) {
            return cachedIcon
        }
        
        let icon = loadIcon(for: process)
        
        // Cache the result
        if let icon = icon {
            setCachedIcon(icon, for: cacheKey)
        }
        
        return icon
    }
    
    /// Preloads icons for a batch of processes
    func preloadIcons(for processes: [ProcessInfo]) {
        DispatchQueue.global(qos: .background).async {
            for process in processes {
                _ = self.getIcon(for: process)
            }
        }
    }
    
    /// Clears the icon cache
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.iconCache.removeAll()
        }
    }
    
    // MARK: - Private Implementation
    
    private func loadIcon(for process: ProcessInfo) -> NSImage? {
        switch process.processType {
        case .userApplication, .systemApplication:
            return getApplicationIcon(for: process)
        case .systemDaemon:
            return getSystemDaemonIcon(for: process)
        case .userDaemon:
            return getUserDaemonIcon(for: process)
        case .backgroundTask:
            return getBackgroundTaskIcon(for: process)
        case .kernel:
            return getKernelIcon(for: process)
        case .unknown:
            return getUnknownIcon(for: process)
        }
    }
    
    private func getApplicationIcon(for process: ProcessInfo) -> NSImage? {
        // Try to get the actual application icon
        if let appIcon = getApplicationIconFromBundle(process.fullPath) {
            return appIcon
        }
        
        // Try to get icon from running application
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == Int32(process.pid) }) {
            return runningApp.icon
        }
        
        // Fallback to system icon
        return NSImage(systemSymbolName: process.processType.systemIconName, accessibilityDescription: process.processType.rawValue)
    }
    
    private func getApplicationIconFromBundle(_ path: String) -> NSImage? {
        // Extract .app bundle path
        if let appRange = path.range(of: ".app") {
            let appPath = String(path[...appRange.upperBound])
            let cleanAppPath = appPath.replacingOccurrences(of: ".app/", with: ".app")
            
            // Try to get icon from the app bundle
            if FileManager.default.fileExists(atPath: cleanAppPath) {
                let icon = NSWorkspace.shared.icon(forFile: cleanAppPath)
                if icon.size.width > 0 && icon.size.height > 0 {
                    return icon
                }
            }
            
            // Try to find the app in common locations
            let appName = URL(fileURLWithPath: cleanAppPath).lastPathComponent
            let searchPaths = [
                "/Applications/\(appName)",
                "/System/Applications/\(appName)",
                "/Applications/Utilities/\(appName)"
            ]
            
            for searchPath in searchPaths {
                if FileManager.default.fileExists(atPath: searchPath) {
                    let icon = NSWorkspace.shared.icon(forFile: searchPath)
                    if icon.size.width > 0 && icon.size.height > 0 {
                        return icon
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getSystemDaemonIcon(for process: ProcessInfo) -> NSImage? {
        // Special icons for known system daemons
        let command = process.command.lowercased()
        
        switch command {
        case "launchd":
            return NSImage(systemSymbolName: "gear.badge.checkmark", accessibilityDescription: "System Launch Daemon")
        case "kernel_task":
            return NSImage(systemSymbolName: "cpu.fill", accessibilityDescription: "Kernel Task")
        case "mds", "mdworker":
            return NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Spotlight")
        case "bluetoothd":
            return NSImage(systemSymbolName: "bluetooth", accessibilityDescription: "Bluetooth")
        case "wifivelocityd", "airportd":
            return NSImage(systemSymbolName: "wifi", accessibilityDescription: "Wi-Fi")
        case "logd", "syslogd":
            return NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: "System Log")
        case "powerd":
            return NSImage(systemSymbolName: "battery.100", accessibilityDescription: "Power Management")
        case "networkd", "configd":
            return NSImage(systemSymbolName: "network", accessibilityDescription: "Network")
        case "securityd", "trustd":
            return NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "Security")
        case "locationd":
            return NSImage(systemSymbolName: "location.fill", accessibilityDescription: "Location Services")
        default:
            return NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "System Daemon")
        }
    }
    
    private func getUserDaemonIcon(for process: ProcessInfo) -> NSImage? {
        let command = process.command.lowercased()
        
        switch command {
        case let cmd where cmd.contains("dock"):
            return NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "Dock")
        case let cmd where cmd.contains("finder"):
            return NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Finder")
        case let cmd where cmd.contains("systemuiserver"):
            return NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "System UI Server")
        case let cmd where cmd.contains("windowserver"):
            return NSImage(systemSymbolName: "macwindow", accessibilityDescription: "Window Server")
        case let cmd where cmd.contains("loginwindow"):
            return NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: "Login Window")
        case let cmd where cmd.contains("control center"):
            return NSImage(systemSymbolName: "switch.2", accessibilityDescription: "Control Center")
        default:
            return NSImage(systemSymbolName: "person.crop.circle.fill.badge.wrench", accessibilityDescription: "User Daemon")
        }
    }
    
    private func getBackgroundTaskIcon(for process: ProcessInfo) -> NSImage? {
        let command = process.command.lowercased()
        
        if command.contains("safari") {
            return NSImage(systemSymbolName: "safari.fill", accessibilityDescription: "Safari")
        } else if command.contains("chrome") {
            return NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome")
        } else if command.contains("firefox") {
            return NSImage(systemSymbolName: "flame.fill", accessibilityDescription: "Firefox")
        } else if command.contains("backup") || command.contains("timemachine") {
            return NSImage(systemSymbolName: "externaldrive.fill", accessibilityDescription: "Backup")
        } else if command.contains("cloud") {
            return NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Cloud Service")
        } else {
            return NSImage(systemSymbolName: "timer", accessibilityDescription: "Background Task")
        }
    }
    
    private func getKernelIcon(for process: ProcessInfo) -> NSImage? {
        return NSImage(systemSymbolName: "cpu.fill", accessibilityDescription: "Kernel Process")
    }
    
    private func getUnknownIcon(for process: ProcessInfo) -> NSImage? {
        return NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "Unknown Process")
    }
    
    // MARK: - Cache Management
    
    private func getCachedIcon(for key: String) -> NSImage? {
        return cacheQueue.sync {
            return iconCache[key]
        }
    }
    
    private func setCachedIcon(_ icon: NSImage, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.iconCache[key] = icon
        }
    }
}