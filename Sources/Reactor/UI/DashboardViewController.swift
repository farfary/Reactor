import AppKit
import Foundation

class DashboardViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let processManager = ProcessManager()
    private var processes: [ProcessInfo] = []
    private var tableView: NSTableView!
    private var timer: DispatchSourceTimer?

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
    }

    deinit {
        timer?.cancel()
        timer = nil
    }

    private func buildUI() {
        headerLabel.font = .systemFont(ofSize: 12, weight: .regular)
        headerLabel.textColor = .secondaryLabelColor

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24

        let cols: [(String, CGFloat)] = [("Process", 260), ("PID", 70), ("CPU", 70), ("Memory", 100), ("Type", 140)]
        for (title, width) in cols {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(title))
            col.title = title
            col.width = width
            tableView.addTableColumn(col)
        }

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
        t.schedule(deadline: .now() + 1, repeating: 1)
        t.setEventHandler { [weak self] in self?.refresh() }
        timer = t
        t.resume()
    }

    private func refresh() {
        let sys = processManager.getSystemInfo()
        headerLabel.stringValue = "Memory: \(sys.formattedUsedMemory)/\(sys.formattedTotalMemory) (\(sys.formattedMemoryUsage)) — Processes: \(processManager.getCachedProcessesOnly().count)"
        processManager.refreshProcessesAsync(forceRefresh: false) { [weak self] procs in
            guard let self = self else { return }
            self.processes = procs.sorted { lhs, rhs in
                if lhs.cpuUsage == rhs.cpuUsage { return lhs.memoryUsage > rhs.memoryUsage }
                return lhs.cpuUsage > rhs.cpuUsage
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - Table
    func numberOfRows(in tableView: NSTableView) -> Int { processes.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < processes.count, let tableColumn = tableColumn else { return nil }
        let p = processes[row]
        let id = tableColumn.identifier

        let cell = NSTableCellView()
        cell.textField = NSTextField(labelWithString: "")
        cell.textField?.lineBreakMode = .byTruncatingTail
        if id.rawValue == "Process" {
            let h = NSStackView()
            h.orientation = .horizontal
            h.spacing = 6
            let imgView = NSImageView()
            imgView.imageScaling = .scaleProportionallyDown
            imgView.symbolConfiguration = .init(pointSize: 14, weight: .regular)
            imgView.image = processManager.getIcon(for: p) ?? NSImage(systemSymbolName: p.processType.systemIconName, accessibilityDescription: nil)
            imgView.frame.size = NSSize(width: 16, height: 16)
            cell.textField?.stringValue = p.displayName
            h.addArrangedSubview(imgView)
            h.addArrangedSubview(cell.textField!)
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
        case "PID": cell.textField?.stringValue = String(p.pid)
        case "CPU": cell.textField?.stringValue = p.formattedCPUUsage
        case "Memory": cell.textField?.stringValue = p.formattedMemoryUsage
        case "Type": cell.textField?.stringValue = p.processType.rawValue
        default: break
        }

        if let tf = cell.textField {
            cell.addSubview(tf)
            tf.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                tf.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
                tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        }
        return cell
    }
}
