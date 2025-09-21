import Foundation

/// Comprehensive process type classification
enum ProcessType: String, CaseIterable {
    case userApplication = "User Application"
    case systemApplication = "System Application" 
    case backgroundTask = "Background Task"
    case systemDaemon = "System Daemon"
    case userDaemon = "User Daemon"
    case kernel = "Kernel Process"
    case unknown = "Unknown"
    
    /// System icon name for the process type
    var systemIconName: String {
        switch self {
        case .userApplication:
            return "app.fill"
        case .systemApplication:
            return "gear.badge.checkmark"
        case .backgroundTask:
            return "timer"
        case .systemDaemon:
            return "wrench.and.screwdriver.fill"
        case .userDaemon:
            return "person.crop.circle.fill.badge.wrench"
        case .kernel:
            return "cpu.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    /// Color representation for UI
    var displayColor: String {
        switch self {
        case .userApplication:
            return "blue"
        case .systemApplication:
            return "green"
        case .backgroundTask:
            return "orange"
        case .systemDaemon:
            return "red"
        case .userDaemon:
            return "purple"
        case .kernel:
            return "gray"
        case .unknown:
            return "black"
        }
    }
    
    /// Priority level for display ordering
    var displayPriority: Int {
        switch self {
        case .userApplication: return 1
        case .systemApplication: return 2
        case .backgroundTask: return 3
        case .userDaemon: return 4
        case .systemDaemon: return 5
        case .kernel: return 6
        case .unknown: return 7
        }
    }
}

/// Process category for grouping in UI
enum ProcessCategory: String, CaseIterable {
    case applications = "Applications"
    case systemServices = "System Services"
    case backgroundProcesses = "Background Processes"
    case daemons = "Daemons"
    case kernelProcesses = "Kernel Processes"
    
    var types: [ProcessType] {
        switch self {
        case .applications:
            return [.userApplication, .systemApplication]
        case .systemServices:
            return [.systemDaemon]
        case .backgroundProcesses:
            return [.backgroundTask]
        case .daemons:
            return [.userDaemon, .systemDaemon]
        case .kernelProcesses:
            return [.kernel]
        }
    }
    
    var displayPriority: Int {
        switch self {
        case .applications: return 1
        case .systemServices: return 2
        case .backgroundProcesses: return 3
        case .daemons: return 4
        case .kernelProcesses: return 5
        }
    }
}