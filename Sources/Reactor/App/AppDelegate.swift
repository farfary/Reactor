import AppKit
import Foundation

/// Main application delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let menuBarManager = MenuBarManager()
    
    // MARK: - NSApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ReactorLogger.logAndPrint("🚀 Reactor application starting...", 
                                 type: .info, category: ReactorLogger.app, categoryName: "App")
        
        // Ensure we're running as an accessory app (menubar only)
        NSApp.setActivationPolicy(.accessory)
        ReactorLogger.logAndPrint("Set app activation policy to accessory", 
                                 type: .debug, category: ReactorLogger.app, categoryName: "App")
        
        // Setup the menubar
        menuBarManager.setupMenuBar()
        
        ReactorLogger.logAndPrint("✅ Reactor application launch completed", 
                                 type: .info, category: ReactorLogger.app, categoryName: "App")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ReactorLogger.logAndPrint("🛑 Reactor is shutting down...", 
                                 type: .info, category: ReactorLogger.app, categoryName: "App")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        // Since this is a menubar app, don't terminate when windows close
        return false
    }
}