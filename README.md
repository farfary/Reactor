
# Reactor ⚡

A modern, lightweight macOS menubar application for real-time monitoring and management of system processes. Built with Swift and AppKit, Reactor is designed for seamless development and use entirely from VS Code—no Xcode required.

<p align="center">
    <img src="https://via.placeholder.com/64x64/007ACC/FFFFFF?text=⚡" alt="Reactor Icon" width="64" />
</p>

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Development](#development)
- [Architecture](#architecture)
- [Technical Details](#technical-details)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)


## Features

- **🔍 Live Process Menu**: Instantly view the top CPU and memory-consuming processes in your menubar dropdown.
- **⚡ Interactive Process Management**: Terminate any process with a single click and confirmation dialog.
- **🔄 On-Demand Refresh**: Process list updates every time you open the menu or manually refresh.
- **🎯 Lightweight**: Minimal resource usage, always available in your menubar.
- **🌙 Native macOS Integration**: Full support for dark mode and system preferences.
- **📊 Visual Indicators**: High CPU processes marked with 🔥, moderate with ⚡.
- **🛡️ Safe Termination**: Attempts graceful SIGTERM first, then SIGKILL if needed.


## Screenshots

> *Screenshots coming soon!*


## Installation

### Prerequisites

- **macOS** 12.0 or later
- **Swift** 5.8 or later
- **VS Code** (no Xcode required)

### Quick Start

1. **Clone the Repository**
    ```zsh
    git clone <your-repo-url> ~/Desktop/Reactor
    cd ~/Desktop/Reactor
    ```

2. **Build the Project**
    ```zsh
    swift build
    ```

3. **Run the Application**
    ```zsh
    swift run
    ```

#### Development Mode

For debugging and verbose output:

```zsh
swift build --configuration debug
swift run --configuration debug
```


## Usage

1. **Launch**: Run `swift run` from the project directory.
2. **Access**: Look for the ⚡ icon in your macOS menubar.
3. **Monitor**: Click the icon to see the top 10 CPU-intensive processes in the dropdown menu.
4. **Manage**: Click any process to terminate it (with confirmation dialog).
5. **Refresh**: The process list updates every time you open the menu or click "🔄 Refresh Processes".

### Menu Features

- **Live Process List**: Top 10 processes by CPU usage.
- **Visual Indicators**: 
    - 🔥 High CPU usage (>50%)
    - ⚡ Moderate CPU usage (>20%)
- **Process Actions**: Click to kill (with confirmation)
- **🔄 Refresh Processes**: Manual refresh option
- **About Reactor**: App info
- **Quit Reactor**: Exit the app

### Process Information Display

Each process entry shows:
- **Rank**: CPU usage order (1-10)
- **Process Name**: Clean, readable
- **CPU Usage**: % of CPU
- **Memory Usage**: % of system memory
- **PID**: Process ID (in tooltip)


## Development

### Project Structure

```
Reactor/
├── Package.swift              # Swift Package Manager config
├── README.md                  # Project documentation
└── Sources/
    └── Reactor/
        ├── main.swift         # App entry point, UI setup
        └── ProcessMonitor.swift # Process monitoring & management
```

### Building from VS Code

1. **Open Terminal**: `View → Terminal`
2. **Navigate**: `cd ~/Desktop/Reactor`
3. **Build**: `swift build`
4. **Run**: `swift run`
5. **Debug**: Add print/log statements and rebuild

### Adding Features

To extend Reactor:

1. **Add Menu Items**: Edit `constructMenu()` in `main.swift`
2. **Extend ProcessMonitor**: Add methods to `ProcessMonitor.swift`
3. **Handle Actions**: Add `@objc` methods in `AppDelegate`

**Example: Add "Show Memory Usage"**

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

---

## Architecture

- **AppDelegate**: Handles app lifecycle and menubar setup
- **Menu Construction**: Dynamically builds the menubar menu
- **ProcessMonitor**: Scans, parses, and manages system processes
- **Data Models**: Structures for process and memory info


## Technical Details

### Dependencies
- **AppKit**: Menubar integration, UI
- **Foundation**: System process interaction, data handling

### System Commands Used
- `ps -axo pid,pcpu,pmem,comm --sort=-pcpu`: List processes
- `kill -TERM <pid>`: Graceful termination
- `kill -9 <pid>`: Force termination
- `vm_stat`: Memory stats

### Performance
- Minimal CPU usage when idle
- On-demand process queries only
- No background polling or timers


## Troubleshooting

### Common Issues & Solutions

- **"Command not found: swift"**
    - Install Xcode Command Line Tools: `xcode-select --install`
- **Permission denied when killing processes**
    - Some processes require admin rights. Try `sudo swift run` (not recommended for daily use).
- **App doesn't appear in menubar**
    - Check terminal output for errors
    - Ensure macOS 12.0+ is installed
- **Build errors**
    - Confirm all files are in correct directories
    - Check Swift version: `swift --version`

### Debug Mode

Run with debug output:
```zsh
swift run --configuration debug
```


## Roadmap

### Planned Features
- [ ] 🎨 Enhanced UI with SwiftUI
- [ ] 📈 Real-time CPU/memory graphs
- [ ] 🔔 High resource usage notifications
- [ ] ⚙️ Preferences panel
- [ ] 📊 Process history & analytics
- [ ] 🔍 Process search/filtering
- [ ] 📱 Interactive management
- [ ] 🎯 CPU/Memory usage alerts

### Enhancements
- [ ] Dynamic live process menu
- [ ] Keyboard shortcuts
- [ ] Export to CSV
- [ ] Activity Monitor integration
- [ ] Custom refresh intervals


## Contributing

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature-name`
3. **Make changes & test**: `swift build && swift run`
4. **Commit**: `git commit -am 'Add feature'`
5. **Push**: `git push origin feature-name`
6. **Open a pull request**


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
- Open an issue on GitHub
- Check the [Troubleshooting](#troubleshooting) section
- Review VS Code terminal output for errors

---

<p align="center"><em>Built with ❤️ using Swift and VS Code</em></p>