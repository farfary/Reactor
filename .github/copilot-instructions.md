# Reactor - AI Coding Instructions

## Project Overview

Reactor is a macOS menubar application that provides comprehensive system process monitoring in real-time. It's built using Swift Package Manager with AppKit framework for native macOS integration.

**Key Technologies:**

- Swift 5.8+ (macOS 12.0+ deployment target)
- AppKit for native macOS UI
- Swift Package Manager (no external dependencies)
- Foundation and os.log for system integration

## Architecture

Reactor follows a clean, modular architecture with clear separation of concerns:

```
Sources/Reactor/
├── App/
│   └── AppDelegate.swift           # App lifecycle management
├── Extensions/
│   └── [String extensions]         # String utilities
├── Models/
│   ├── ProcessInfo.swift           # Process data model
│   └── ProcessType.swift           # Process classification enum
├── Services/
│   ├── ProcessClassifier.swift     # Process categorization logic
│   ├── ProcessIconService.swift    # System icon resolution
│   ├── ProcessManager.swift        # Central service coordinator
│   └── ProcessScanningService.swift # Process discovery & parsing
├── UI/
│   └── MenuBarManager.swift        # MenuBar UI management
├── ReactorLogger.swift             # Centralized logging system
└── main.swift                      # Application entry point
```

## Coding Conventions

### 1. Logging Standards

**Always use ReactorLogger for all logging:**

```swift
import Foundation

// Standard logging pattern
ReactorLogger.logAndPrint("🔍 Starting operation...",
                         type: .info,
                         category: ReactorLogger.process,
                         categoryName: "Process")

// Available categories:
ReactorLogger.app          // General app events
ReactorLogger.ui           // UI-related events
ReactorLogger.process      // Process operations
ReactorLogger.system       // System interactions
ReactorLogger.performance  // Performance metrics
```

**Emoji conventions for log messages:**

- 🔍 = Starting operations/scanning
- ✅ = Success/completion
- ⚠️ = Warnings/fallbacks
- ❌ = Errors/failures
- 🔄 = Retries/alternatives
- 📊 = Performance/metrics

### 2. Service Architecture

**Service composition pattern used throughout:**

```swift
// In ProcessManager.swift - Central coordinator
class ProcessManager: ObservableObject {
    private let scanningService: ProcessScanningService
    private let iconService: ProcessIconService
    private let classifier: ProcessClassifier

    init(scanningService: ProcessScanningService = ProcessScanningService(),
         iconService: ProcessIconService = ProcessIconService(),
         classifier: ProcessClassifier = ProcessClassifier()) {
        // Dependency injection for testability
    }
}
```

**Key principles:**

- Services are single-responsibility
- Use dependency injection for testability
- Services don't directly depend on each other (go through ProcessManager)
- All services use ReactorLogger for consistent logging

### 3. Error Handling

**Graceful degradation pattern:**

```swift
func getProcesses() -> [ProcessInfo] {
    do {
        // Try primary method
        return try getProcessesWithShell()
    } catch {
        ReactorLogger.logAndPrint("⚠️ Primary method failed, using fallback",
                                 type: .default,
                                 category: ReactorLogger.process,
                                 categoryName: "Process")
        // Fall back to alternative method
        return getProcessesBasic()
    }
}
```

### 4. Process Classification

**Use ProcessType enum for categorization:**

```swift
enum ProcessType: String, CaseIterable {
    case application = "Application"
    case systemService = "System Service"
    case developerTool = "Developer Tool"
    // ... other cases

    var systemIconName: String {
        switch self {
        case .application: return "app.fill"
        case .systemService: return "gear.circle.fill"
        // ... etc
        }
    }
}
```

## Development Workflow

### Build System

**Primary build tools:**

```bash
# Swift Package Manager (preferred for development)
swift build
swift run

# Production builds
make build      # Creates optimized binary
make install    # Installs to /usr/local/bin
make clean      # Cleans build artifacts
```

### Project Structure Rules

1. **Models/**: Pure data structures, no business logic
2. **Services/**: Business logic, stateless when possible
3. **UI/**: AppKit-specific code, minimal business logic
4. **App/**: Application lifecycle and coordination
5. **Extensions/**: Utility extensions, keep minimal

### Testing Guidelines

**When adding new features:**

- Services should be easily testable via dependency injection
- Use ProcessManager as the coordination layer
- Log all significant operations for debugging
- Implement graceful fallbacks for system operations

## Common Patterns

### 1. Async Operations with Timeouts

```swift
func executeWithTimeout<T>(_ operation: @escaping () throws -> T,
                          timeout: TimeInterval = 5.0) async -> T? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let result = try? operation()
            continuation.resume(returning: result)
        }
    }
}
```

### 2. Performance Monitoring

```swift
let startTime = CFAbsoluteTimeGetCurrent()
// ... operation ...
let duration = CFAbsoluteTimeGetCurrent() - startTime
ReactorLogger.logAndPrint("✅ Operation completed in \(String(format: "%.3f", duration))s",
                         type: .info,
                         category: ReactorLogger.performance,
                         categoryName: "Performance")
```

### 3. Menu Construction

```swift
// In MenuBarManager.swift
private func buildMenu() -> NSMenu {
    let menu = NSMenu()

    // Add process items with icons and formatting
    for process in processManager.getSortedProcesses() {
        let item = NSMenuItem(title: process.formattedTitle, action: nil, keyEquivalent: "")
        item.image = processManager.getIcon(for: process)
        menu.addItem(item)
    }

    return menu
}
```

## Integration Points

### System Integration

**Process data sources:**

- Primary: `ps` command via Process API (with timeout)
- Fallback: NSWorkspace.shared for running applications
- Icons: NSWorkspace icon resolution with ProcessType fallbacks

### UI Integration

**MenuBar management:**

- Single NSStatusItem for system tray
- Dynamic menu construction based on current processes
- NSMenuDelegate for menu lifecycle

## Platform Considerations

**macOS-specific features:**

- Requires macOS 12.0+ for modern Process APIs
- Uses AppKit for native menu bar integration
- Leverages NSWorkspace for application discovery
- os.log integration for system logging

## Performance Notes

**Optimization strategies:**

- Process scanning includes built-in timeout (5s default)
- Icon resolution is cached via ProcessIconService
- Menu updates are triggered only when needed
- Memory usage monitoring included in process data

## Security & Permissions

**System access requirements:**

- No special entitlements required
- Uses standard UNIX process tools (`ps`)
- Read-only access to system process information
- No network access or file system writing

## When Adding New Features

1. **Always start with ReactorLogger** - Add appropriate logging first
2. **Follow the service pattern** - New functionality goes in Services/
3. **Update ProcessManager** - Coordinate through the central manager
4. **Handle errors gracefully** - Implement fallbacks where possible
5. **Use ProcessType enum** - For any process categorization needs
6. **Test the Makefile** - Ensure production builds still work
7. **Consider performance** - Add timing logs for significant operations

## Common Debugging

**Log analysis:**

- All logs include emoji prefixes for easy scanning
- Category filtering available through ReactorLogger
- Performance metrics automatically included
- Error paths clearly marked with ❌

**Build issues:**

- Ensure Swift 5.8+ compatibility
- Check macOS deployment target (12.0+)
- Verify Package.swift executable configuration
- Use `make clean` for clean rebuilds
