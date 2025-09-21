import AppKit
import Foundation

class DashboardViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let processManager = ProcessManager()
    private var processes: [ProcessInfo] = []
    private var tableView: NSTableView!
    private var timer: DispatchSourceTimer?
    private let defaults = UserDefaults.standard

    private let headerLabel = NSTextField(labelWithString: "")

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        buildUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
        startTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .reactorSettingsChanged, object: nil)
    }

    deinit {
        timer?.cancel()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }

    private func buildUI() {
        headerLabel.font = .systemFont(ofSize: 12, weight: .regular)
        headerLabel.textColor = .secondaryLabelColor

    let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false

        tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        let cols: [(String, CGFloat, CGFloat)] = [
            ("Process", 300, 250),
            ("PID", 80, 70),
            ("CPU", 90, 80),
            ("Memory", 120, 110),
            ("Type", 160, 140)
        ]
        for (title, width, minWidth) in cols {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(title))
            col.title = title
            col.width = width
            col.minWidth = minWidth
            col.resizingMask = [.autoresizingMask]
            tableView.addTableColumn(col)
        }

        tableView.sizeLastColumnToFit()

        scrollView.documentView = tableView

        let stack = NSStackView(views: [headerLabel, scrollView])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }

    private func startTimer() {
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        let interval = max(1, defaults.integer(forKey: "refreshInterval"))
        t.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval))
        t.setEventHandler { [weak self] in self?.refresh() }
        timer = t
        t.resume()
    }

    @objc private func settingsChanged() {
        // Restart timer with new interval and refresh immediately
        startTimer()
        refresh()
    }

    private func refresh() {
        let sys = processManager.getSystemInfo()
        headerLabel.stringValue = "Memory: \(sys.formattedUsedMemory)/\(sys.formattedTotalMemory) (\(sys.formattedMemoryUsage))"
        processManager.refreshProcessesAsync(forceRefresh: false) { [weak self] procs in
            guard let self = self else { return }
            var list = procs
            // Optional filter: hide system processes if user disabled visibility
            if self.defaults.bool(forKey: "showSystemProcesses") == false {
                list = list.filter { $0.processType == .userApplication || $0.processType == .userDaemon || $0.processType == .backgroundTask }
            }

            self.processes = list.sorted { lhs, rhs in
                if lhs.cpuUsage == rhs.cpuUsage { return lhs.memoryUsage > rhs.memoryUsage }
                return lhs.cpuUsage > rhs.cpuUsage
            }
            self.tableView.reloadData()
            self.updateHeaderCount()
        }
    }

    private func updateHeaderCount() {
        let sys = processManager.getSystemInfo()
        // Extend the header with the current table count to reflect filters
        headerLabel.stringValue = "Memory: \(sys.formattedUsedMemory)/\(sys.formattedTotalMemory) (\(sys.formattedMemoryUsage)) — Showing: \(processes.count) processes"
    }

    // MARK: - Table
    func numberOfRows(in tableView: NSTableView) -> Int { processes.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < processes.count, let tableColumn = tableColumn else { return nil }
        let p = processes[row]
        let id = tableColumn.identifier

    let cell = NSTableCellView()
    let label = NSTextField(labelWithString: "")
    label.lineBreakMode = .byTruncatingTail
        if id.rawValue == "Process" {
            let h = NSStackView()
            h.orientation = .horizontal
            h.spacing = 6
            let imgView = NSImageView()
            imgView.imageScaling = .scaleProportionallyDown
            imgView.symbolConfiguration = .init(pointSize: 14, weight: .regular)
            imgView.image = processManager.getIcon(for: p) ?? NSImage(systemSymbolName: p.processType.systemIconName, accessibilityDescription: nil)
            imgView.frame.size = NSSize(width: 16, height: 16)
            label.stringValue = p.displayName
            h.addArrangedSubview(imgView)
            h.addArrangedSubview(label)
            cell.addSubview(h)
            h.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                h.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                h.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
                h.topAnchor.constraint(equalTo: cell.topAnchor, constant: 2),
                h.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -2)
            ])
            return cell
        }

        switch id.rawValue {
        case "PID": label.stringValue = String(p.pid)
        case "CPU": label.stringValue = p.formattedCPUUsage
        case "Memory": label.stringValue = p.formattedMemoryUsage
        case "Type": label.stringValue = p.processType.rawValue
        default: break
        }

        cell.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
