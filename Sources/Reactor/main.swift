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
        
        // Start with a loading placeholder
        let loadingItem = NSMenuItem(title: "Loading processes...", action: nil, keyEquivalent: "")
        loadingItem.isEnabled = false
        menu.addItem(loadingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let refreshItem = NSMenuItem(title: "🔄 Refresh Processes", action: #selector(refreshProcesses), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "About Reactor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Reactor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
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
            let processTitle = String(format: "%d. %@ (%.1f%% CPU, %.1f%% MEM)", 
                                    index + 1, 
                                    process.command, 
                                    process.cpu, 
                                    process.memory)
            
            let processItem = NSMenuItem(title: processTitle, action: #selector(processSelected(_:)), keyEquivalent: "")
            processItem.target = self
            processItem.tag = 999 // Mark as process item (we'll use representedObject for PID)
            processItem.representedObject = process.pid
            processItem.toolTip = "PID: \(process.pid) - Click to kill this process"
            
            // Add visual indicators for high usage
            if process.cpu > 50.0 {
                processItem.title = "🔥 " + processTitle
            } else if process.cpu > 20.0 {
                processItem.title = "⚡ " + processTitle
            }
            
            menu.insertItem(processItem, at: insertIndex)
            insertIndex += 1
        }
        
        ReactorLogger.logAndPrint("✅ Updated menu with \(processes.count) process items", type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }
    
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