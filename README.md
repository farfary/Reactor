# Reactor 🔥

A lightweight macOS menubar application for monitoring and managing system processes. Built with Swift, AppKit, and designed to run entirely from VS Code without requiring Xcode.

![Reactor Icon](https://via.placeholder.com/64x64/007ACC/FFFFFF?text=⚡)

## Features

- **🔍 Live Process Menu**: View top CPU and memory consuming processes directly in the menubar dropdown
- **⚡ Interactive Process Management**: Click on any process to terminate it with confirmation dialog
- **🔄 Auto-Refresh**: Process list updates automatically when you open the menubar menu
- **🎯 Lightweight**: Minimal resource usage, stays in your menubar
- **🌙 System Integration**: Supports macOS dark mode and system preferences
- **📊 Visual Indicators**: High CPU processes are marked with 🔥 and moderate usage with ⚡
- **�️ Safe Termination**: Uses SIGTERM first, then SIGKILL if needed for graceful process handling

## Screenshots

> *Screenshots will be added here*

## Installation

### Prerequisites

- macOS 12.0 or later
- Swift 5.8 or later
- VS Code (no Xcode required!)

### Quick Setup

1. **Clone or Download**
   ```bash
   cd ~/Desktop
   git clone <your-repo-url> Reactor
   # OR create the project directory manually
   mkdir Reactor && cd Reactor
   ```

2. **Copy the Project Files**
   - Copy all the files from this repository into your `~/Desktop/Reactor/` directory
   - Ensure the directory structure matches:
     ```
     Reactor/
     ├── Package.swift
     ├── README.md
     └── Sources/
         └── Reactor/
             ├── main.swift
             └── ProcessMonitor.swift
     ```

3. **Build the Project**
   ```bash
   cd ~/Desktop/Reactor
   swift build
   ```

4. **Run the Application**
   ```bash
   swift run
   ```

### Alternative: Development Mode

For development and testing:

```bash
# Build in debug mode
swift build --configuration debug

# Run with verbose output
swift run --configuration debug
```

## Usage

1. **Launch**: Run `swift run` from the project directory
2. **Access**: Look for the ⚡ bolt icon in your macOS menubar
3. **Monitor**: Click the icon to see the top 10 CPU-intensive processes listed directly in the dropdown menu
4. **Manage**: Click on any process in the list to terminate it (with confirmation dialog)
5. **Refresh**: The process list updates automatically each time you open the menu, or click "🔄 Refresh Processes"

### Menu Features

- **Live Process List**: Top 10 processes sorted by CPU usage appear directly in the menu
- **Visual Indicators**: 
  - 🔥 High CPU usage (>50%)
  - ⚡ Moderate CPU usage (>20%)
- **Process Actions**: Click any process to kill it (with safety confirmation)
- **🔄 Refresh Processes**: Manually refresh the process list
- **About Reactor**: Shows application information
- **Quit Reactor**: Closes the application

### Process Information Display

Each process shows:
- **Rank**: Position in CPU usage (1-10)
- **Process Name**: Cleaned, readable process name
- **CPU Usage**: Percentage of CPU being used
- **Memory Usage**: Percentage of system memory being used
- **PID**: Process ID (shown in tooltip)

## Development

### Project Structure

```
Reactor/
├── Package.swift              # Swift Package Manager configuration
├── README.md                  # This file
└── Sources/
    └── Reactor/
        ├── main.swift         # App entry point and UI setup
        └── ProcessMonitor.swift # Process monitoring and management logic
```

### Key Components

#### `main.swift`
- **AppDelegate**: Main application delegate handling menubar setup
- **Menu Construction**: Creates and manages the menubar menu
- **Event Handling**: Responds to user interactions

#### `ProcessMonitor.swift`
- **Process Listing**: Fetches and parses system process information
- **Process Management**: Handles process termination (SIGTERM/SIGKILL)
- **Memory Monitoring**: Retrieves system memory statistics
- **Data Models**: Structures for process and memory information

### Building from VS Code

1. **Open Terminal in VS Code**: `View → Terminal`
2. **Navigate to Project**: `cd ~/Desktop/Reactor`
3. **Build**: `swift build`
4. **Run**: `swift run`
5. **Debug**: Add print statements and rebuild

### Adding Features

To extend Reactor's functionality:

1. **Add Menu Items**: Modify `constructMenu()` in `main.swift`
2. **Extend ProcessMonitor**: Add new methods to `ProcessMonitor.swift`
3. **Handle Actions**: Create corresponding `@objc` methods in `AppDelegate`

Example: Adding a "Show Memory Usage" feature:

```swift
// In main.swift constructMenu()
let memoryItem = NSMenuItem(title: "Show Memory Usage", action: #selector(showMemoryUsage), keyEquivalent: "m")
memoryItem.target = self
menu.addItem(memoryItem)

// Add the action method
@objc func showMemoryUsage() {
    if let memInfo = processMonitor.getSystemMemoryInfo() {
        print("Memory Usage: \(String(format: "%.1f", memInfo.memoryUsagePercentage))%")
        print("Used: \(String(format: "%.2f", memInfo.usedMemoryGB))GB / \(String(format: "%.2f", memInfo.totalMemoryGB))GB")
    }
}
```

## Technical Details

### Dependencies
- **AppKit**: For menubar integration and UI components
- **Foundation**: For system process interaction and data handling

### System Commands Used
- `ps -axo pid,pcpu,pmem,comm --sort=-pcpu`: Process listing
- `kill -TERM <pid>`: Graceful process termination
- `kill -9 <pid>`: Force process termination
- `vm_stat`: Memory statistics

### Performance
- Minimal CPU usage when idle
- Process queries on-demand only
- No background polling or timers

## Troubleshooting

### Common Issues

**"Command not found: swift"**
- Install Xcode Command Line Tools: `xcode-select --install`

**"Permission denied" when killing processes**
- Some system processes require admin privileges
- Try running with `sudo swift run` (not recommended for regular use)

**App doesn't appear in menubar**
- Check terminal output for error messages
- Ensure macOS version compatibility (12.0+)

**Build errors**
- Verify all files are in the correct directory structure
- Check Swift version: `swift --version`

### Debug Mode

Run with debug output:
```bash
swift run --configuration debug
```

## Roadmap

### Planned Features
- [ ] 🎨 Enhanced UI with SwiftUI views
- [ ] 📈 Real-time CPU/memory graphs
- [ ] 🔔 Notifications for high resource usage
- [ ] ⚙️ Preferences panel
- [ ] 📊 Process history and analytics
- [ ] 🔍 Process search and filtering
- [ ] 📱 Interactive process management
- [ ] 🎯 CPU/Memory usage alerts

### Enhancements
- [ ] Dynamic menu showing live processes
- [ ] Keyboard shortcuts for common actions
- [ ] Export process data to CSV
- [ ] Integration with Activity Monitor
- [ ] Custom refresh intervals

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test: `swift build && swift run`
4. Commit changes: `git commit -am 'Add feature'`
5. Push to branch: `git push origin feature-name`
6. Submit a pull request

## License

MIT License

Copyright (c) 2025 Reactor

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

## Support

For issues, feature requests, or questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review the VS Code terminal output for error messages

---

**Built with ❤️ using Swift and VS Code**