import AppKit

/// 상태바 메뉴. 설정 항목은 설정 창으로 옮기고, 여기에는 현재 상태와 바로가기만 둔다.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let metrics: SystemMetrics
    private let cpuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    var onOpenSettings: (() -> Void)?

    init(metrics: SystemMetrics) {
        self.metrics = metrics
        super.init()
        menu.delegate = self
        cpuItem.isEnabled = false

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        let activityItem = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        activityItem.target = self

        menu.items = [
            cpuItem,
            .separator(),
            settingsItem,
            activityItem,
            .separator(),
            NSMenuItem(title: "Quit RunCat Clone", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        cpuItem.title = String(format: "CPU: %.1f%%", metrics.cpu.percent)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
}
