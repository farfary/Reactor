import AppKit

/// Entry point for the Reactor application
// Create the application instance
let app = NSApplication.shared

// Set up the delegate
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
app.run()