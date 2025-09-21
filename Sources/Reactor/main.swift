import AppKit
import Foundation
import os.log

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    let processMonitor = ProcessMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ReactorLogger.logAndPrint("🚀 Reactor application starting...", type: .info, category: ReactorLogger.app, categoryName: "App")
        
        // Ensure we're running as an accessory app (menubar only)
        NSApp.setActivationPolicy(.accessory)
        ReactorLogger.logAndPrint("Set app activation policy to accessory", type: .debug, category: ReactorLogger.app, categoryName: "App")
        
        setupMenubar()
        
        ReactorLogger.logAndPrint("✅ Reactor application launch completed", type: .info, category: ReactorLogger.app, categoryName: "App")
    }
    
    private func setupMenubar() {
        ReactorLogger.logAndPrint("Setting up menubar status item...", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else {
            ReactorLogger.logAndPrint("❌ Failed to create status item", type: .error, category: ReactorLogger.ui, categoryName: "UI")
            return
        }
        
        ReactorLogger.logAndPrint("✅ Status item created successfully", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        // Configure the button
        if let button = statusItem.button {
            ReactorLogger.logAndPrint("Configuring status bar button...", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
            
            // Set the icon
            if let image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "Reactor") {
                button.image = image
                button.image?.size = NSSize(width: 18, height: 18)
                button.image?.isTemplate = true
                ReactorLogger.logAndPrint("✅ Button icon set successfully", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
            } else {
                ReactorLogger.logAndPrint("⚠️ Failed to load system symbol, using fallback", type: .error, category: ReactorLogger.ui, categoryName: "UI")
                button.title = "⚡"
            }
            
            // Set button properties for better interaction
            button.toolTip = "Reactor - Process Monitor"
            button.appearsDisabled = false
            
            ReactorLogger.logAndPrint("Button configuration completed", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        } else {
            ReactorLogger.logAndPrint("❌ Failed to get status item button", type: .error, category: ReactorLogger.ui, categoryName: "UI")
            return
        }
        
        // Create and set the menu
        constructMenu()
        
        ReactorLogger.logAndPrint("✅ Menubar setup completed successfully", type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }
    
    func constructMenu() {
        ReactorLogger.logAndPrint("🔨 Constructing menu...", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        let menu = NSMenu()
        menu.delegate = self
        
        // Add header with system info
        addSystemInfoHeader(to: menu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Start with a loading placeholder for processes
        let loadingItem = NSMenuItem(title: "🔄 Loading processes...", action: nil, keyEquivalent: "")
        loadingItem.isEnabled = false
        loadingItem.tag = 999 // Mark for removal
        menu.addItem(loadingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Control section
        addControlSection(to: menu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Info section
        addInfoSection(to: menu)
        
        // CRITICAL: Assign the menu to the status item FIRST
        statusItem?.menu = menu
        
        let itemCount = menu.items.count
        ReactorLogger.logAndPrint("✅ Menu constructed with \(itemCount) items and assigned to status item", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        // Load processes asynchronously after menu is set up
        DispatchQueue.global(qos: .userInitiated).async {
            let processes = self.processMonitor.getProcessList()
            let topProcesses = Array(processes.prefix(10))
            
            DispatchQueue.main.async {
                self.updateProcessMenuItems(in: menu, with: topProcesses)
            }
        }
    }
    
    /// Adds system information header to the menu
    private func addSystemInfoHeader(to menu: NSMenu) {
        let headerItem = NSMenuItem()
        headerItem.isEnabled = false
        
        // Get basic system info
        let processCount = Foundation.ProcessInfo.processInfo.processorCount
        let systemVersion = Foundation.ProcessInfo.processInfo.operatingSystemVersionString
        
        let headerText = "⚙️ Reactor - System Monitor\n💻 \(processCount) cores • \(systemVersion)"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor
        ]
        
        headerItem.attributedTitle = NSAttributedString(string: headerText, attributes: headerAttributes)
        menu.addItem(headerItem)
    }
    
    /// Adds control section to the menu
    private func addControlSection(to menu: NSMenu) {
        let refreshItem = NSMenuItem(title: "🔄 Refresh Processes", action: #selector(refreshProcesses), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let killAllItem = NSMenuItem(title: "⚠️ Force Quit All High CPU", action: #selector(killHighCPUProcesses), keyEquivalent: "")
        killAllItem.target = self
        menu.addItem(killAllItem)
    }
    
    /// Force kills all high CPU processes (>50%)
    @objc func killHighCPUProcesses() {
        ReactorLogger.logAndPrint("🚨 User requested to kill all high CPU processes", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        let alert = NSAlert()
        alert.messageText = "Force Quit High CPU Processes?"
        alert.informativeText = "This will terminate all processes using more than 50% CPU. This action cannot be undone and may cause data loss."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Force Quit All")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let processes = processMonitor.getProcessList()
            let highCPUProcesses = processes.filter { $0.cpu > 50.0 }
            
            ReactorLogger.logAndPrint("Found \(highCPUProcesses.count) high CPU processes to terminate", type: .info, category: ReactorLogger.process, categoryName: "Process")
            
            for process in highCPUProcesses {
                let success = processMonitor.killProcess(pid: process.pid)
                ReactorLogger.logProcessTermination(pid: process.pid, processName: process.command, success: success)
            }
            
            // Refresh the menu after killing processes
            refreshProcesses()
        }
    }
    
    /// Adds info section to the menu
    private func addInfoSection(to menu: NSMenu) {
        let aboutItem = NSMenuItem(title: "ℹ️ About Reactor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "❌ Quit Reactor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // Updated process menu management - this method now updates existing menu items
    func updateProcessMenuItems(in menu: NSMenu, with processes: [ProcessInfo]) {
        ReactorLogger.logAndPrint("🔄 Updating process menu items...", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        // Remove old process items (keep separator and bottom items)
        var itemsToRemove: [NSMenuItem] = []
        for item in menu.items {
            if item.title == "Loading processes..." || (item.tag == 999) {
                itemsToRemove.append(item)
            }
        }
        
        for item in itemsToRemove {
            menu.removeItem(item)
        }
        
        // Add new process items at the top
        var insertIndex = 0
        for (index, process) in processes.enumerated() {
            let processItem = createEnhancedProcessMenuItem(for: process, rank: index + 1)
            menu.insertItem(processItem, at: insertIndex)
            insertIndex += 1
        }
        
        ReactorLogger.logAndPrint("✅ Updated menu with \(processes.count) process items", type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }
    
    /// Creates an enhanced menu item with icon and detailed two-line layout
    private func createEnhancedProcessMenuItem(for process: ProcessInfo, rank: Int) -> NSMenuItem {
        // Create the menu item
        let processItem = NSMenuItem()
        processItem.target = self
        processItem.action = #selector(processSelected(_:))
        processItem.tag = 999 // Mark as process item
        processItem.representedObject = process.pid
        
        // Create attributed title with two-line layout
        let attributedTitle = createTwoLineProcessTitle(for: process, rank: rank)
        processItem.attributedTitle = attributedTitle
        
        // Set icon if available
        if let icon = processMonitor.getProcessIcon(for: process) {
            // Resize icon to appropriate size for menu
            let iconSize = NSSize(width: 16, height: 16)
            icon.size = iconSize
            processItem.image = icon
        }
        
        // Create detailed tooltip
        let tooltip = createDetailedTooltip(for: process)
        processItem.toolTip = tooltip
        
        return processItem
    }
    
    /// Creates a two-line attributed title for the process
    private func createTwoLineProcessTitle(for process: ProcessInfo, rank: Int) -> NSAttributedString {
        let title = NSMutableAttributedString()
        
        // First line: Process name with rank and type icon
        let processTypeIcon = process.processType.icon
        let firstLine = String(format: "%@ %d. %@", processTypeIcon, rank, process.displayName)
        let firstLineAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        title.append(NSAttributedString(string: firstLine, attributes: firstLineAttributes))
        
        // Add performance indicators
        if process.cpu > 50.0 {
            title.append(NSAttributedString(string: " 🔥", attributes: firstLineAttributes))
        } else if process.cpu > 20.0 {
            title.append(NSAttributedString(string: " ⚡", attributes: firstLineAttributes))
        }
        
        // Second line: Detailed stats
        let secondLine = String(format: "\nPID: %d • CPU: %.1f%% • Memory: %.1f%% • Type: %@", 
                               process.pid, 
                               process.cpu, 
                               process.memory,
                               process.processType == .application ? "App" : 
                               process.processType == .system ? "System" : "Daemon")
        let secondLineAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        title.append(NSAttributedString(string: secondLine, attributes: secondLineAttributes))
        
        return title
    }
    
    /// Creates a detailed tooltip for the process
    private func createDetailedTooltip(for process: ProcessInfo) -> String {
        var tooltip = "Process Details:\n"
        tooltip += "Name: \(process.displayName)\n"
        tooltip += "PID: \(process.pid)\n" 
        tooltip += "CPU Usage: \(String(format: "%.1f", process.cpu))%\n"
        tooltip += "Memory Usage: \(String(format: "%.1f", process.memory))%\n"
        tooltip += "Type: \(process.processType == .application ? "Application" : process.processType == .system ? "System Process" : "Daemon")\n"
        if !process.fullPath.isEmpty && process.fullPath != process.command {
            tooltip += "Full Path: \(process.fullPath)\n"
        }
        tooltip += "\nClick to terminate this process"
        return tooltip
    }
    
    // MARK: - Action Methods
    
    @objc func processSelected(_ sender: NSMenuItem) {
        // Try to get PID from representedObject first, then fall back to tag
        let pid: Int
        if let representedPid = sender.representedObject as? Int {
            pid = representedPid
        } else {
            pid = sender.tag
        }
        
        let processName = sender.title.components(separatedBy: " ").dropFirst().joined(separator: " ")
        
        ReactorLogger.logAndPrint("🎯 User selected process for termination: \(processName) (PID: \(pid))", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        let alert = NSAlert()
        alert.messageText = "Kill Process?"
        alert.informativeText = "Are you sure you want to terminate process \(processName) (PID: \(pid))?\n\nThis action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill Process")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            ReactorLogger.logAndPrint("⚔️ User confirmed process termination for PID: \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
            
            let success = processMonitor.killProcess(pid: pid)
            
            // Log the result
            ReactorLogger.logProcessTermination(pid: pid, processName: processName, success: success)
            
            // Show result notification
            let resultAlert = NSAlert()
            if success {
                resultAlert.messageText = "Process Terminated"
                resultAlert.informativeText = "Process \(pid) has been successfully terminated."
                resultAlert.alertStyle = .informational
                ReactorLogger.logAndPrint("✅ Process termination successful for PID: \(pid)", type: .info, category: ReactorLogger.process, categoryName: "Process")
            } else {
                resultAlert.messageText = "Failed to Terminate Process"
                resultAlert.informativeText = "Could not terminate process \(pid). It may have already exited or require higher privileges."
                resultAlert.alertStyle = .warning
                ReactorLogger.logAndPrint("❌ Process termination failed for PID: \(pid)", type: .error, category: ReactorLogger.process, categoryName: "Process")
            }
            resultAlert.addButton(withTitle: "OK")
            resultAlert.runModal()
            
            // Refresh the menu
            refreshProcesses()
        } else {
            ReactorLogger.logAndPrint("❌ User cancelled process termination for PID: \(pid)", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        }
    }
    
    @objc func refreshProcesses() {
        ReactorLogger.logAndPrint("🔄 Refreshing process list...", type: .info, category: ReactorLogger.ui, categoryName: "UI")
        // Reconstruct the entire menu with updated process list
        constructMenu()
        ReactorLogger.logAndPrint("✅ Process list refreshed successfully", type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }
    
    @objc func showAbout() {
        ReactorLogger.logAndPrint("ℹ️ Showing about dialog", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        let alert = NSAlert()
        alert.messageText = "Reactor v1.0"
        alert.informativeText = "A macOS menubar app for monitoring and managing system processes.\n\nBuilt with Swift and AppKit."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        ReactorLogger.logAndPrint("👋 User requested app quit", type: .info, category: ReactorLogger.app, categoryName: "App")
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSApplicationDelegate
    
    func applicationWillTerminate(_ notification: Notification) {
        ReactorLogger.logAndPrint("🛑 Reactor is shutting down...", type: .info, category: ReactorLogger.app, categoryName: "App")
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        ReactorLogger.logAndPrint("📂 Menu opening", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        // Don't auto-refresh on menu open to avoid hanging - user can manually refresh if needed
    }
    
    func menuDidClose(_ menu: NSMenu) {
        ReactorLogger.logAndPrint("📁 Menu closed", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
    }
}

// Entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()