import AppKit
import Foundation

/// Main window hosting the Task Manager (Dashboard + Settings)
class MainWindowController: NSWindowController {
    private let tabController = NSTabViewController()

    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                              styleMask: [.titled, .closable, .resizable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        window.title = "Reactor — Task Manager"
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupContent()
    }

    private func setupContent() {
        // Tabs: Dashboard, Settings
        let dashboard = DashboardViewController()
        dashboard.title = "Dashboard"

        let settings = SettingsViewController()
        settings.title = "Settings"

        tabController.tabStyle = .toolbar
        tabController.addChild(dashboard)
        tabController.addChild(settings)

        window?.contentViewController = tabController
    }
}
