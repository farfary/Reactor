# Reactor ⚡

A sophisticated macOS menubar application for real-time system process monitoring and management. Built with modern Swift, featuring a clean modular architecture and comprehensive logging system.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0+-red.svg)
![Swift](https://img.shields.io/badge/Swift-5.8+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- **🔍 Live Process Monitoring**: Real-time display of system processes with CPU and memory usage
- **⚡ Smart Process Classification**: Automatic categorization of applications, system services, and developer tools
- **🎯 Interactive Management**: Click-to-terminate processes with intelligent confirmation dialogs
- **🔄 Dynamic Updates**: Process list refreshes automatically when menubar is accessed
- **� Visual Process Types**: Color-coded icons and indicators for different process categories
- **📊 Performance Metrics**: Detailed CPU and memory usage with formatted display
- **🛡️ Safe Termination**: Graceful process handling with proper signal management
- **🌙 System Integration**: Native macOS menubar integration with dark mode support
- **📝 Comprehensive Logging**: Detailed logging system with categorized output for debugging
- **⚙️ Modular Architecture**: Clean separation of concerns with service-oriented design

## Screenshots

> *Screenshots coming soon - showing the modern menubar interface with process categorization*

## Installation

### Prerequisites

- **macOS 12.0+** (Monterey or later)
- **Swift 5.8+** and Xcode Command Line Tools
- **Terminal** or **VS Code** (no Xcode required)

### Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/farfary/Reactor.git
   cd Reactor
   ```

2. **Build with Swift Package Manager**
   ```bash
   swift build --configuration release
   ```

3. **Run the Application**
   ```bash
   swift run
   ```

### Alternative Installation Methods

#### Using Make (Recommended for Production)
```bash
# Build optimized release version
make build

# Install to /usr/local/bin (requires sudo)
make install

# Run installed version
reactor
```

#### Development Build
```bash
# Debug build with verbose logging
swift build --configuration debug
swift run --configuration debug
```

### Troubleshooting Installation

**Missing Command Line Tools:**
```bash
xcode-select --install
```

**Permission Issues:**
```bash
# For system process monitoring (optional)
sudo swift run
```

## Usage

### Basic Operation

1. **Launch**: Run `swift run` or `reactor` (if installed) from terminal
2. **Access**: Look for the ⚡ icon in your macOS menubar (top-right area)
3. **Monitor**: Click the icon to view categorized processes with real-time metrics
4. **Manage**: Click any process to terminate it (with smart confirmation dialogs)
5. **Refresh**: Process list updates automatically, or use "🔄 Refresh" for manual updates

### Process Categories

Reactor intelligently categorizes processes with distinct visual indicators:

- **� Applications**: User applications and productivity tools
- **⚙️ System Services**: Core macOS system processes
- **🛠️ Developer Tools**: Xcode, VS Code, terminals, and development utilities
- **☁️ Cloud Services**: Dropbox, OneDrive, backup services
- **🔒 Security**: Antivirus, VPN, security applications
- **🎮 Games**: Gaming applications and platforms
- **🌐 Web Browsers**: Safari, Chrome, Firefox, and browser helpers
- **💬 Communication**: Slack, Discord, messaging applications
- **🎵 Media**: Music, video, and media processing applications

### Advanced Features

#### Process Information Display
Each process entry shows:
- **🏷️ Category Icon**: Visual process type indicator
- **📊 CPU Usage**: Real-time CPU consumption percentage
- **💾 Memory Usage**: Physical memory usage in MB/GB
- **🆔 Process ID**: PID for system reference
- **📝 Command Path**: Full executable path (in detailed view)

#### Smart Termination
- **Graceful Shutdown**: Attempts SIGTERM first for clean exits
- **Force Termination**: Falls back to SIGKILL for unresponsive processes
- **System Protection**: Warns before terminating critical system processes
- **Confirmation Dialogs**: Smart prompts based on process importance

## Architecture

Reactor is built with a clean, modular architecture emphasizing separation of concerns and testability:

```
Sources/Reactor/
├── App/
│   └── AppDelegate.swift           # Application lifecycle management
├── Extensions/
│   └── String+Extensions.swift     # String utility extensions
├── Models/
│   ├── ProcessInfo.swift           # Process data model
│   └── ProcessType.swift           # Process classification system
├── Services/
│   ├── ProcessClassifier.swift     # Intelligent process categorization
│   ├── ProcessIconService.swift    # System icon resolution
│   ├── ProcessManager.swift        # Central coordination service
│   └── ProcessScanningService.swift # Process discovery & parsing
├── UI/
│   └── MenuBarManager.swift        # MenuBar interface management
├── ReactorLogger.swift             # Centralized logging system
└── main.swift                      # Application entry point
```

### Core Components

#### **ProcessManager** - Central Coordinator
- Orchestrates all process-related operations
- Manages service dependencies through dependency injection
- Provides caching and performance optimization
- Handles service lifecycle and error recovery

#### **ProcessScanningService** - System Integration
- Interfaces with macOS process APIs (`ps` command, NSWorkspace)
- Implements timeout handling and graceful fallbacks
- Parses process data with robust error handling
- Provides real-time process discovery

#### **ProcessClassifier** - Intelligence Layer
- Categorizes processes based on executable names and paths
- Maintains comprehensive classification rules
- Supports dynamic classification updates
- Provides fallback classification strategies

#### **ProcessIconService** - Visual Enhancement
- Resolves system icons for applications and processes
- Caches icon resources for performance
- Provides fallback icons for unknown processes
- Integrates with macOS icon system

#### **ReactorLogger** - Observability
- Centralized logging with categorized subsystems
- Performance timing and metrics collection
- Structured logging with emoji-based visual indicators
- Debug and production logging modes

#### **MenuBarManager** - User Interface
- Native AppKit menubar integration
- Dynamic menu construction and updates
- Event handling and user interaction management
- Responsive UI with real-time data updates

### Design Principles

- **Service-Oriented Architecture**: Clear separation between data, business logic, and presentation
- **Dependency Injection**: Services are injected for better testability and modularity
- **Graceful Degradation**: Multiple fallback strategies for system integration
- **Performance-First**: Caching, timeouts, and optimized data structures
- **Comprehensive Logging**: Detailed observability for debugging and monitoring
- **Error Resilience**: Robust error handling with user-friendly fallbacks

## Development

### Build System

Reactor supports multiple build workflows for different development needs:

#### Swift Package Manager (Development)
```bash
# Debug build with full logging
swift build --configuration debug
swift run --configuration debug

# Release build for testing
swift build --configuration release
swift run --configuration release
```

#### Make (Production)
```bash
# Optimized production build
make build

# Install system-wide
make install

# Clean build artifacts
make clean

# Create app bundle
make app
```

### Development Workflow

#### Setting Up Development Environment
1. **Clone and Setup**
   ```bash
   git clone https://github.com/farfary/Reactor.git
   cd Reactor
   ```

2. **VS Code Integration**
   ```bash
   # Open in VS Code
   code .
   
   # Build and run from integrated terminal
   swift build && swift run
   ```

3. **Enable Debug Logging**
   - All services use `ReactorLogger` with categorized output
   - Debug builds include verbose logging with emoji indicators
   - Performance metrics are automatically collected

#### Code Organization Guidelines

##### Adding New Features
1. **Create Service**: Add new functionality in `Services/` directory
2. **Update Models**: Extend `ProcessInfo` or `ProcessType` as needed
3. **Integrate in ProcessManager**: Wire up new services through dependency injection
4. **Add Logging**: Use `ReactorLogger` with appropriate categories and emoji indicators
5. **Update UI**: Modify `MenuBarManager` for user-facing changes

##### Example: Adding Network Monitoring
```swift
// 1. Create Services/NetworkMonitor.swift
class NetworkMonitor {
    func getNetworkUsage() -> NetworkInfo {
        ReactorLogger.logAndPrint("🌐 Scanning network usage...", 
                                 type: .info, 
                                 category: ReactorLogger.system,
                                 categoryName: "Network")
        // Implementation here
    }
}

// 2. Integrate in ProcessManager.swift
class ProcessManager {
    private let networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
    }
}

// 3. Add to MenuBarManager.swift
private func buildNetworkSection() -> [NSMenuItem] {
    let networkInfo = processManager.getNetworkUsage()
    // Build menu items
}
```

### Testing and Debugging

#### Logging Categories
Reactor uses structured logging with these categories:

- **`ReactorLogger.app`**: Application lifecycle events
- **`ReactorLogger.ui`**: User interface and menu operations  
- **`ReactorLogger.process`**: Process scanning and management
- **`ReactorLogger.system`**: System API interactions
- **`ReactorLogger.performance`**: Performance metrics and timing

#### Debug Commands
```bash
# View all logs in Console.app (filter by "Reactor")
log stream --predicate 'subsystem == "com.reactor.app"'

# Performance profiling
instruments -t "Time Profiler" $(swift build --show-bin-path)/Reactor

# Memory debugging
leaks --atExit -- $(swift build --show-bin-path)/Reactor
```

#### Common Development Tasks

**Adding Process Categories:**
```swift
// In Models/ProcessType.swift
enum ProcessType: String, CaseIterable {
    case newCategory = "New Category"
    
    var systemIconName: String {
        switch self {
        case .newCategory: return "new.icon.name"
        }
    }
}
```

**Extending Process Information:**
```swift
// In Models/ProcessInfo.swift
struct ProcessInfo {
    let newProperty: String
    
    var formattedNewProperty: String {
        return "Formatted: \(newProperty)"
    }
}
```

**Adding Menu Actions:**
```swift
// In UI/MenuBarManager.swift
private func addCustomMenuItem() -> NSMenuItem {
    let item = NSMenuItem(title: "Custom Action", 
                         action: #selector(handleCustomAction), 
                         keyEquivalent: "")
    item.target = self
    return item
}

@objc private func handleCustomAction() {
    ReactorLogger.logAndPrint("🎯 Custom action triggered", 
                             type: .info, 
                             category: ReactorLogger.ui,
                             categoryName: "Menu")
}
```

## Technical Implementation

### System Integration

#### Process Data Sources
- **Primary**: macOS `ps` command via Swift `Process` API with timeout handling
- **Fallback**: `NSWorkspace.shared` for application discovery
- **System APIs**: Native macOS process and memory management APIs

#### Performance Optimizations
- **Intelligent Caching**: ProcessManager caches process data and icons
- **Timeout Management**: 5-second timeout for process scanning operations
- **Lazy Loading**: Menu items created on-demand during menu presentation
- **Memory Efficiency**: Structured data with minimal memory footprint

#### Error Handling Strategy
- **Graceful Degradation**: Multiple fallback methods for data collection
- **User-Friendly Errors**: Meaningful error messages with suggested actions
- **System Protection**: Prevents termination of critical system processes
- **Logging Integration**: All errors logged with context and recovery actions

### Dependencies and APIs

#### Core Technologies
- **AppKit**: Native macOS menubar and UI integration
- **Foundation**: System process interaction and data structures
- **os.log**: Structured logging with categorized subsystems
- **Swift Concurrency**: Modern async/await for responsive operations

#### System Commands Utilized
```bash
# Process discovery and monitoring
ps -axo pid,pcpu,pmem,comm --sort=-pcpu

# Memory statistics
vm_stat

# Process termination
kill -TERM <pid>  # Graceful termination
kill -9 <pid>     # Force termination
```

#### Platform Requirements
- **macOS 12.0+**: Required for modern Process API and structured logging
- **Swift 5.8+**: Leverages modern Swift concurrency and type system
- **No External Dependencies**: Pure Swift Package Manager with system frameworks only

### Security and Permissions

#### System Access
- **Standard Permissions**: Uses standard UNIX process tools without special entitlements
- **Read-Only Operations**: Process monitoring requires no special permissions
- **Process Termination**: Uses standard kill signals available to user processes
- **Privacy Compliance**: No data collection, network access, or file system writing

#### Safety Features
- **Process Classification**: Identifies and warns about system-critical processes
- **Confirmation Dialogs**: Smart prompts based on process importance and type
- **Signal Progression**: Attempts graceful termination before force-kill
- **Error Recovery**: Handles permission denied scenarios gracefully

## Troubleshooting

### Installation Issues

#### Command Line Tools Missing
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
swift --version
xcode-select -p
```

#### Build Failures
```bash
# Clean and rebuild
make clean
swift package clean
swift build

# Check Swift version compatibility
swift --version  # Should be 5.8+

# Verify package dependencies
swift package resolve
```

#### Permission Issues
```bash
# For enhanced process access (optional)
sudo swift run

# For installation to system directories
sudo make install
```

### Runtime Issues

#### Menubar Icon Not Appearing
1. **Check Terminal Output**: Look for error messages during startup
2. **System Compatibility**: Ensure macOS 12.0+ compatibility
3. **Process Conflicts**: Check if another menubar app is interfering
4. **Debug Mode**: Run with `swift run --configuration debug` for verbose output

#### Process Termination Failures
- **System Processes**: Some require elevated privileges
- **Protected Applications**: macOS protects certain applications
- **Permissions**: Try running with `sudo` for system processes
- **Alternative Methods**: Use Activity Monitor for stubborn processes

#### Performance Issues
```bash
# Check resource usage
top -pid $(pgrep Reactor)

# View logging output
log stream --predicate 'subsystem == "com.reactor.app"'

# Profile performance
instruments -t "Time Profiler" /path/to/Reactor
```

### Development Debugging

#### Logging Categories
Enable specific logging categories for targeted debugging:

```swift
// In ReactorLogger.swift - adjust log levels
public static let app = OSLog(subsystem: "com.reactor.app", category: "App")
public static let process = OSLog(subsystem: "com.reactor.app", category: "Process")
public static let performance = OSLog(subsystem: "com.reactor.app", category: "Performance")
```

#### Common Debug Commands
```bash
# View real-time logs
log stream --predicate 'subsystem == "com.reactor.app"' --level debug

# Check memory usage
leaks --atExit -- $(swift build --show-bin-path)/Reactor

# Profile CPU usage
sample Reactor 10 -file reactor-profile.txt
```

#### Build System Debugging
```bash
# Verbose build output
swift build --verbose

# Check package dependencies
swift package show-dependencies

# Resolve dependency conflicts
swift package resolve --force-resolved-versions
```

### Getting Help

For additional support:

1. **Check Logs**: Review Console.app logs filtered by "Reactor"
2. **GitHub Issues**: Report bugs with system info and logs
3. **Debug Mode**: Run with `--configuration debug` for detailed output
4. **System Information**: Include macOS version, Swift version, and hardware specs

## Roadmap

### Current Version (1.0)
- ✅ **Core Process Monitoring**: Real-time process discovery and management
- ✅ **Intelligent Classification**: Smart process categorization system
- ✅ **MenuBar Integration**: Native macOS menubar interface
- ✅ **Comprehensive Logging**: Structured logging with performance metrics
- ✅ **Modular Architecture**: Service-oriented design with dependency injection
- ✅ **Error Resilience**: Graceful fallbacks and robust error handling

### Planned Features (1.1)
- 🔄 **Real-Time Updates**: Live process monitoring with automatic refresh
- 📊 **Enhanced Metrics**: Memory pressure, disk I/O, and network usage
- 🎨 **Visual Improvements**: Process graphs and usage indicators
- ⚙️ **User Preferences**: Customizable refresh intervals and display options
- 🔍 **Search & Filter**: Quick process search and category filtering
- � **Usage History**: Track process behavior over time

### Future Enhancements (1.2+)
- 🔔 **Smart Notifications**: Alerts for high resource usage or suspicious activity
- 📱 **SwiftUI Interface**: Modern declarative UI with improved user experience
- 🎯 **Process Insights**: Detailed analysis and recommendations
- 🛡️ **Security Features**: Process verification and threat detection
- 📊 **System Overview**: CPU, memory, disk, and network dashboards
- 🔧 **Advanced Tools**: Process priority management and resource limits
- 📱 **Shortcuts Integration**: macOS Shortcuts support for automation
- 🌐 **Remote Monitoring**: Optional network-based monitoring capabilities

### Technical Roadmap
- **Performance**: Sub-100ms menu rendering for thousands of processes
- **Platform**: Support for macOS 13+ features and APIs
- **Testing**: Comprehensive unit and integration test suite
- **Documentation**: API documentation and developer guides
- **Accessibility**: Full VoiceOver and accessibility support
- **Localization**: Multi-language support for international users

### Community Features
- 🔌 **Plugin System**: Extensible architecture for third-party enhancements
- 📋 **Export Options**: CSV, JSON export for process data
- 🎨 **Themes**: Customizable appearance and color schemes
- 🔧 **Configuration**: Advanced settings and customization options

## Contributing

We welcome contributions to Reactor! Here's how to get started:

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/Reactor.git
   cd Reactor
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set Up Development Environment**
   ```bash
   # Install dependencies and build
   swift package resolve
   swift build --configuration debug
   
   # Run tests (when available)
   swift test
   ```

### Contribution Guidelines

#### Code Standards
- **Follow existing architecture**: Use the service-oriented pattern
- **Add comprehensive logging**: Use `ReactorLogger` with appropriate categories
- **Include error handling**: Implement graceful fallbacks
- **Write self-documenting code**: Clear variable names and function signatures
- **Performance considerations**: Profile changes that affect scanning or UI

#### Example Contribution Workflow
```bash
# 1. Make changes and test locally
swift build && swift run

# 2. Add logging for new features
ReactorLogger.logAndPrint("🔍 New feature working...", 
                         type: .info, 
                         category: ReactorLogger.app,
                         categoryName: "Feature")

# 3. Test error scenarios
# 4. Update documentation if needed
# 5. Commit with descriptive message
git commit -am "Add network monitoring feature

- Implement NetworkMonitor service
- Add network usage display in menu
- Include fallback for network API failures
- Add comprehensive logging for debugging"

# 6. Push and create pull request
git push origin feature/your-feature-name
```

#### Pull Request Guidelines
- **Clear Description**: Explain what the change does and why
- **Test Instructions**: Provide steps to test the new functionality
- **Screenshots**: Include before/after images for UI changes
- **Breaking Changes**: Document any API or behavior changes
- **Performance Impact**: Note any performance implications

### Areas for Contribution

#### High-Priority
- 📊 **Performance Improvements**: Optimize process scanning and menu rendering
- 🔍 **Process Search**: Add search and filtering capabilities
- 📱 **SwiftUI Migration**: Modernize UI components
- 🧪 **Testing Framework**: Add unit and integration tests

#### Medium-Priority
- 🎨 **Visual Enhancements**: Improve icons and process indicators
- 📈 **Additional Metrics**: Add network, disk I/O monitoring
- ⚙️ **User Preferences**: Settings panel and customization
- 🔔 **Notifications**: Smart alerts for resource usage

#### Documentation
- 📖 **API Documentation**: Document service interfaces
- 🎯 **Usage Examples**: Add more code examples
- 🌐 **Localization**: Multi-language support
- 📝 **Architecture Guide**: Detailed architectural documentation

### Community Guidelines

- **Be Respectful**: Follow the code of conduct
- **Ask Questions**: Use GitHub Issues for questions and discussions
- **Share Ideas**: Propose features in GitHub Discussions
- **Help Others**: Assist with issues and code review

## License

MIT License

Copyright (c) 2025 Reactor Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Acknowledgments

- **Swift Community**: For excellent tooling and language design
- **macOS Developers**: For comprehensive system APIs and documentation  
- **Open Source Contributors**: For inspiration and best practices
- **Process Monitoring Tools**: Activity Monitor, htop, and similar tools for inspiration

## Support and Contact

### Getting Help
- 📖 **Documentation**: Check this README and inline code documentation
- 🐛 **Bug Reports**: Create detailed GitHub Issues with logs and system info
- 💡 **Feature Requests**: Use GitHub Discussions for feature ideas
- 🔧 **Development Questions**: Ask in GitHub Issues with "question" label

### Project Links
- **Homepage**: [GitHub Repository](https://github.com/farfary/Reactor)
- **Issues**: [Report Bugs](https://github.com/farfary/Reactor/issues)
- **Discussions**: [Feature Ideas](https://github.com/farfary/Reactor/discussions)
- **Releases**: [Download Latest](https://github.com/farfary/Reactor/releases)

### System Requirements Reminder
- **macOS**: 12.0+ (Monterey or later)
- **Swift**: 5.8+ 
- **Architecture**: Intel and Apple Silicon supported
- **Permissions**: Standard user access (sudo optional for system processes)

---

**Built with ❤️ using Swift, AppKit, and modern macOS development practices**

*Reactor - Empowering developers with real-time system insights*