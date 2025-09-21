import AppKit
import Foundation

class SettingsViewController: NSViewController {
    private let refreshLabel = NSTextField(labelWithString: "Refresh Interval (seconds):")
    private let refreshField = NSTextField(string: "1")
    private let showSystemLabel = NSTextField(labelWithString: "Show system processes in lists")
    private let showSystemCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    private let defaults = UserDefaults.standard

    override func loadView() {
        self.view = NSView()
        buildUI()
    }

    private func buildUI() {
        let grid = NSGridView(views: [
            [refreshLabel, refreshField],
            [showSystemLabel, showSystemCheckbox]
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        view.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])

        refreshField.target = self
        refreshField.action = #selector(savePreferences)
        showSystemCheckbox.target = self
        showSystemCheckbox.action = #selector(savePreferences)

        loadPreferences()
    }

    private func loadPreferences() {
        let refresh = max(1, defaults.integer(forKey: "refreshInterval"))
        refreshField.stringValue = String(refresh)
        showSystemCheckbox.state = defaults.bool(forKey: "showSystemProcesses") ? .on : .off
    }

    @objc private func savePreferences() {
        let refresh = Int(refreshField.stringValue) ?? 1
        defaults.set(max(1, refresh), forKey: "refreshInterval")
        defaults.set(showSystemCheckbox.state == .on, forKey: "showSystemProcesses")
        ReactorLogger.logAndPrint("✅ Preferences saved (refresh=\(max(1, refresh)), showSystem=\(showSystemCheckbox.state == .on))", type: .info, category: ReactorLogger.app, categoryName: "Settings")
        NotificationCenter.default.post(name: .reactorSettingsChanged, object: nil)
    }
}
