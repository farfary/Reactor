import AppKit
import Foundation

/// Responsible for creating and managing the menubar UI
class MenuBarManager: NSObject, NSMenuDelegate {
    
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private let processManager = ProcessManager()
    private var pidItemMap: [Int: NSMenuItem] = [:]
    private var memoryItemRef: NSMenuItem?
    private var processCountItemRef: NSMenuItem?
    private var liveUpdateTimer: DispatchSourceTimer?
    private var menuOpen: Bool = false
    
    // MARK: - Setup
    
    func setupMenuBar() {
        ReactorLogger.logAndPrint("Setting up menubar status item...", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else {
            ReactorLogger.logAndPrint("❌ Failed to create status item", 
                                     type: .error, category: ReactorLogger.ui, categoryName: "UI")
            return
        }
        
        ReactorLogger.logAndPrint("✅ Status item created successfully", 
                                 type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        configureStatusButton(statusItem)
        constructMenu()
        
        ReactorLogger.logAndPrint("✅ Menubar setup completed successfully", 
                                 type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }
    
    // MARK: - Private Methods
    
    private func configureStatusButton(_ statusItem: NSStatusItem) {
        guard let button = statusItem.button else { return }
        
        ReactorLogger.logAndPrint("Configuring status bar button...", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        // Set the icon
        if let image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "Reactor") {
            button.image = image
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            ReactorLogger.logAndPrint("✅ Button icon set successfully", 
                                     type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        } else {
            ReactorLogger.logAndPrint("⚠️ Failed to load system symbol, using fallback", 
                                     type: .error, category: ReactorLogger.ui, categoryName: "UI")
            button.title = "⚡"
        }
        
        button.toolTip = "Reactor - Process Monitor"
        ReactorLogger.logAndPrint("Button configuration completed", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
    }
    
    private func constructMenu() {
        guard let statusItem = statusItem else { return }
        
        ReactorLogger.logAndPrint("🔨 Constructing menu...", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        let menu = NSMenu()
        menu.delegate = self
        pidItemMap.removeAll()
        memoryItemRef = nil
        processCountItemRef = nil
        
        // Use cached processes immediately to avoid blocking UI
        let cached = processManager.getCachedProcessesOnly()
        addSystemInfoHeader(to: menu, cachedCount: cached.count)
        addProcessSections(to: menu, with: cached)

        // If no cache or a refresh is needed, show loading indicator and kick off async refresh
        if cached.isEmpty || !processManager.isCacheFresh() {
            let loading = NSMenuItem()
            loading.title = "⏳ Loading processes…"
            loading.isEnabled = false
            menu.addItem(NSMenuItem.separator())
            menu.addItem(loading)
        }
        
        // Add control section
        addControlSection(to: menu)
        
        // Add info section
        addInfoSection(to: menu)
        
        statusItem.menu = menu
        
        ReactorLogger.logAndPrint("✅ Menu constructed and assigned to status item", 
                                 type: .info, category: ReactorLogger.ui, categoryName: "UI")

        // Trigger a background refresh to update menu when completed
        processManager.refreshProcessesAsync(forceRefresh: cached.isEmpty) { [weak self] fresh in
            guard let self = self else { return }
            if self.menuOpen {
                // Update in-place to keep menu open and live
                self.updateMenuItems(with: fresh)
            } else {
                // Rebuild menu on main thread with fresh data
                self.rebuildMenuWithFreshData()
            }
        }
    }
    
    private func addSystemInfoHeader(to menu: NSMenu, cachedCount: Int) {
        let systemInfo = processManager.getSystemInfo()
        
        // System header
        let headerItem = NSMenuItem()
        headerItem.title = "⚡ Reactor System Monitor"
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // Memory info
        let memoryItem = NSMenuItem()
        memoryItem.title = "💾 Memory: \(systemInfo.formattedUsedMemory) / \(systemInfo.formattedTotalMemory) (\(systemInfo.formattedMemoryUsage))"
        memoryItem.isEnabled = false
        memoryItemRef = memoryItem
        menu.addItem(memoryItem)
        
        // Process count (use cached value to avoid sync scan)
        let processCount = cachedCount
        let processCountItem = NSMenuItem()
        processCountItem.title = "📊 Total Processes: \(processCount)"
        processCountItem.isEnabled = false
        processCountItemRef = processCountItem
        menu.addItem(processCountItem)
        
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addProcessSections(to menu: NSMenu, with processes: [ProcessInfo]) {
        // Build categories locally from provided list to avoid synchronous calls
        var categorizedProcesses: [ProcessCategory: [ProcessInfo]] = [:]
        for category in ProcessCategory.allCases { categorizedProcesses[category] = [] }
        for p in processes { categorizedProcesses[p.category, default: []].append(p) }
        
        for category in ProcessCategory.allCases.sorted(by: { $0.displayPriority < $1.displayPriority }) {
            guard let processes = categorizedProcesses[category], !processes.isEmpty else { continue }
            
            // Add category header
            let categoryItem = NSMenuItem()
            categoryItem.title = "\(category.rawValue) (\(processes.count))"
            categoryItem.isEnabled = false
            menu.addItem(categoryItem)
            
            // Add top processes from this category (limit to avoid menu overflow)
            let limitedProcesses = Array(processes.prefix(5))
            for process in limitedProcesses {
                let processItem = createProcessMenuItem(for: process)
                pidItemMap[process.pid] = processItem
                menu.addItem(processItem)
            }
            
            // If there are more processes, add a "show more" indicator
            if processes.count > 5 {
                let moreItem = NSMenuItem()
                moreItem.title = "  ... and \(processes.count - 5) more"
                moreItem.isEnabled = false
                menu.addItem(moreItem)
            }
            
            menu.addItem(NSMenuItem.separator())
        }
    }
    
    private func createProcessMenuItem(for process: ProcessInfo) -> NSMenuItem {
        let menuItem = NSMenuItem()
        
        // Create attributed title with icon and two-line layout
        let attributedTitle = createAttributedTitle(for: process)
        menuItem.attributedTitle = attributedTitle
        
        // Set up interaction
        menuItem.target = self
        menuItem.action = #selector(processSelected(_:))
        menuItem.representedObject = process.pid
        menuItem.toolTip = process.detailedDescription
        
        return menuItem
    }
    
    private func createAttributedTitle(for process: ProcessInfo) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Add icon if available
        if let icon = processManager.getIcon(for: process) {
            let attachment = NSTextAttachment()
            attachment.image = icon
            attachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
            
            let iconString = NSAttributedString(attachment: attachment)
            attributedString.append(iconString)
            attributedString.append(NSAttributedString(string: " "))
        }
        
        // Primary line: Process name
        let primaryTitle = process.displayName
        let primaryAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        attributedString.append(NSAttributedString(string: primaryTitle, attributes: primaryAttributes))
        
        // Secondary line: Details
        let secondaryTitle = "\n  PID: \(process.pid) • CPU: \(process.formattedCPUUsage) • Memory: \(process.formattedMemoryUsage) • \(process.processType.rawValue)"
        let secondaryAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        attributedString.append(NSAttributedString(string: secondaryTitle, attributes: secondaryAttributes))
        
        return attributedString
    }
    
    private func addControlSection(to menu: NSMenu) {
        let refreshItem = NSMenuItem(title: "🔄 Refresh Processes", action: #selector(refreshProcesses), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addInfoSection(to menu: NSMenu) {
        let aboutItem = NSMenuItem(title: "ℹ️ About Reactor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "❌ Quit Reactor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Action Methods
    
    @objc private func processSelected(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int else { return }
        
        let processes = processManager.getAllProcesses()
        guard let process = processes.first(where: { $0.pid == pid }) else { return }
        
        ReactorLogger.logAndPrint("🎯 User selected process: \(process.displayName) (PID: \(pid))", 
                                 type: .info, category: ReactorLogger.ui, categoryName: "UI")
        
        showProcessActionDialog(for: process)
    }
    
    private func showProcessActionDialog(for process: ProcessInfo) {
        let alert = NSAlert()
        alert.messageText = "Process: \(process.displayName)"
        alert.informativeText = process.detailedDescription + "\nWhat would you like to do?"
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: "Terminate (SIGTERM)")
        alert.addButton(withTitle: "Force Kill (SIGKILL)")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            terminateProcess(process, force: false)
        case .alertSecondButtonReturn:
            terminateProcess(process, force: true)
        default:
            ReactorLogger.logAndPrint("❌ User cancelled process action for PID: \(process.pid)", 
                                     type: .info, category: ReactorLogger.ui, categoryName: "UI")
        }
    }
    
    private func terminateProcess(_ process: ProcessInfo, force: Bool) {
        let success = force ? processManager.forceKillProcess(pid: process.pid) : 
                             processManager.killProcess(pid: process.pid)
        
        let resultAlert = NSAlert()
        if success {
            resultAlert.messageText = "Process \(force ? "Force Killed" : "Terminated")"
            resultAlert.informativeText = "Process \(process.displayName) (PID: \(process.pid)) has been successfully \(force ? "force killed" : "terminated")."
            resultAlert.alertStyle = .informational
        } else {
            resultAlert.messageText = "Failed to \(force ? "Force Kill" : "Terminate") Process"
            resultAlert.informativeText = "Could not \(force ? "force kill" : "terminate") process \(process.displayName) (PID: \(process.pid)). It may have already exited or require higher privileges."
            resultAlert.alertStyle = .warning
        }
        
        resultAlert.addButton(withTitle: "OK")
        resultAlert.runModal()
        
        // Refresh the menu after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshProcesses()
        }
    }
    
    @objc private func refreshProcesses() {
        ReactorLogger.logAndPrint("🔄 User requested process refresh", 
                                 type: .info, category: ReactorLogger.ui, categoryName: "UI")
        // Rebuild immediately from cache and trigger background refresh
        constructMenu()
    }
    
    @objc private func showAbout() {
        ReactorLogger.logAndPrint("ℹ️ Showing about dialog", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        
        let alert = NSAlert()
        alert.messageText = "Reactor v2.0"
        alert.informativeText = """
        A macOS menubar app for monitoring and managing system processes.
        
        Features:
        • Organized process categories
        • User Apps, System Apps, Background Tasks, and Daemons
        • Process icons and detailed information
        • Safe process termination
        
        Built with Swift and AppKit using a modular architecture.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        ReactorLogger.logAndPrint("👋 User requested app quit", 
                                 type: .info, category: ReactorLogger.app, categoryName: "App")
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        ReactorLogger.logAndPrint("📂 Menu opening", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        menuOpen = true
        startLiveUpdates()
    }
    
    func menuDidClose(_ menu: NSMenu) {
        ReactorLogger.logAndPrint("📁 Menu closed", 
                                 type: .debug, category: ReactorLogger.ui, categoryName: "UI")
        menuOpen = false
        stopLiveUpdates()
    }
}

// MARK: - Private helpers (menu rebuilding)
extension MenuBarManager {
    private func rebuildMenuWithFreshData() {
        guard let statusItem = statusItem else { return }
        let menu = NSMenu()
        menu.delegate = self

        let fresh = processManager.getCachedProcessesOnly()
        addSystemInfoHeader(to: menu, cachedCount: fresh.count)
        addProcessSections(to: menu, with: fresh)
        addControlSection(to: menu)
        addInfoSection(to: menu)
        statusItem.menu = menu
        ReactorLogger.logAndPrint("✅ Menu rebuilt with fresh data (\(fresh.count) processes)", type: .info, category: ReactorLogger.ui, categoryName: "UI")
    }

    private func startLiveUpdates() {
        stopLiveUpdates() // ensure only one
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self = self, self.menuOpen else { return }
            self.processManager.refreshProcessesAsync(forceRefresh: false) { [weak self] fresh in
                guard let self = self, self.menuOpen else { return }
                self.updateMenuItems(with: fresh)
            }
        }
        liveUpdateTimer = timer
        timer.resume()
        ReactorLogger.logAndPrint("📡 Live updates started", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
    }

    private func stopLiveUpdates() {
        liveUpdateTimer?.cancel()
        liveUpdateTimer = nil
        ReactorLogger.logAndPrint("🛑 Live updates stopped", type: .debug, category: ReactorLogger.ui, categoryName: "UI")
    }

    private func updateMenuItems(with processes: [ProcessInfo]) {
        // Update header
        let systemInfo = processManager.getSystemInfo()
        memoryItemRef?.title = "💾 Memory: \(systemInfo.formattedUsedMemory) / \(systemInfo.formattedTotalMemory) (\(systemInfo.formattedMemoryUsage))"
        processCountItemRef?.title = "📊 Total Processes: \(processes.count)"

        // If we don't have any per-process items yet (e.g., initial open showed only
        // the loading placeholder), rebuild the menu with the fresh dataset so the
        // categories and process rows appear.
        if pidItemMap.isEmpty && !processes.isEmpty {
            rebuildMenuWithFreshData()
            return
        }

        // Update visible processes (those we created items for)
        for p in processes {
            if let item = pidItemMap[p.pid] {
                item.attributedTitle = createAttributedTitle(for: p)
            }
        }
    }
}