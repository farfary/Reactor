import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    let processMonitor = ProcessMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use system symbol for the menubar icon
            button.image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "Reactor")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
        }
        
        constructMenu()
        
        // Set up menu delegate to refresh processes when menu opens
        statusItem?.menu?.delegate = self
        
        // Keep the app running
        NSApp.setActivationPolicy(.accessory)
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        // Add process list
        addProcessesToMenu(menu)
        
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
        
        statusItem?.menu = menu
    }
    
    func addProcessesToMenu(_ menu: NSMenu) {
        let processes = processMonitor.getProcessList()
        let topProcesses = Array(processes.prefix(10)) // Show top 10 processes
        
        if topProcesses.isEmpty {
            let noProcessItem = NSMenuItem(title: "No processes found", action: nil, keyEquivalent: "")
            noProcessItem.isEnabled = false
            menu.addItem(noProcessItem)
            return
        }
        
        // Add header
        let headerItem = NSMenuItem(title: "Top CPU Processes:", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let font = NSFont.boldSystemFont(ofSize: 13)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        headerItem.attributedTitle = NSAttributedString(string: "Top CPU Processes:", attributes: attributes)
        menu.addItem(headerItem)
        
        // Add each process as a menu item
        for (index, process) in topProcesses.enumerated() {
            let processTitle = String(format: "%d. %@ (%.1f%% CPU, %.1f%% MEM)", 
                                    index + 1, 
                                    process.command, 
                                    process.cpu, 
                                    process.memory)
            
            let processItem = NSMenuItem(title: processTitle, action: #selector(processSelected(_:)), keyEquivalent: "")
            processItem.target = self
            processItem.tag = process.pid // Store PID in tag for later use
            processItem.toolTip = "PID: \(process.pid) - Click to kill this process"
            
            // Add visual indicators for high usage
            if process.cpu > 50.0 {
                processItem.title = "🔥 " + processTitle
            } else if process.cpu > 20.0 {
                processItem.title = "⚡ " + processTitle
            }
            
            menu.addItem(processItem)
        }
    }
    
    @objc func processSelected(_ sender: NSMenuItem) {
        let pid = sender.tag
        let processName = sender.title.components(separatedBy: " ").dropFirst().joined(separator: " ")
        
        let alert = NSAlert()
        alert.messageText = "Kill Process?"
        alert.informativeText = "Are you sure you want to terminate process \(processName) (PID: \(pid))?\n\nThis action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill Process")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let success = processMonitor.killProcess(pid: pid)
            
            // Show result notification
            let resultAlert = NSAlert()
            if success {
                resultAlert.messageText = "Process Terminated"
                resultAlert.informativeText = "Process \(pid) has been successfully terminated."
                resultAlert.alertStyle = .informational
            } else {
                resultAlert.messageText = "Failed to Terminate Process"
                resultAlert.informativeText = "Could not terminate process \(pid). It may have already exited or require higher privileges."
                resultAlert.alertStyle = .warning
            }
            resultAlert.addButton(withTitle: "OK")
            resultAlert.runModal()
            
            // Refresh the menu
            refreshProcesses()
        }
    }
    
    @objc func refreshProcesses() {
        // Reconstruct the entire menu with updated process list
        constructMenu()
        print("Process list refreshed")
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Reactor v1.0"
        alert.informativeText = "A macOS menubar app for monitoring and managing system processes.\n\nBuilt with Swift and AppKit."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("Reactor is shutting down...")
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh the process list every time the menu opens
        refreshProcesses()
    }
}

// Entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()