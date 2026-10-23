import AppKit
import ServiceManagement

/// 상태바 메뉴. 열릴 때마다 설정 값으로 체크 상태를 다시 맞춘다.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let settings: AppSettings
    private let cpuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let runnerMenu = NSMenu()
    private let intervalMenu = NSMenu()
    private let showCPUItem = NSMenuItem(title: "Show CPU Usage", action: #selector(toggleShowCPU), keyEquivalent: "")
    private let slowDownItem = NSMenuItem(title: "Slow Down Under Load", action: #selector(toggleSlowDown), keyEquivalent: "")
    private let flipItem = NSMenuItem(title: "Flip Horizontally", action: #selector(toggleFlip), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    /// 설정이 바뀌면 호출된다. AppDelegate 가 러너/모니터에 반영한다.
    var onChange: (() -> Void)?
    var cpuPercent: Double = 0

    init(settings: AppSettings) {
        self.settings = settings
        super.init()
        menu.delegate = self
        cpuItem.isEnabled = false

        for runner in Runner.builtIns {
            let item = NSMenuItem(title: runner.name, action: #selector(selectRunner(_:)), keyEquivalent: "")
            item.representedObject = runner.id
            item.target = self
            runnerMenu.addItem(item)
        }
        for interval in AppSettings.updateIntervals {
            let item = NSMenuItem(title: "\(Int(interval)) s", action: #selector(selectInterval(_:)), keyEquivalent: "")
            item.representedObject = interval
            item.target = self
            intervalMenu.addItem(item)
        }
        [showCPUItem, slowDownItem, flipItem, launchAtLoginItem].forEach { $0.target = self }

        let runnerItem = NSMenuItem(title: "Runner", action: nil, keyEquivalent: "")
        runnerItem.submenu = runnerMenu
        let intervalItem = NSMenuItem(title: "Update Interval", action: nil, keyEquivalent: "")
        intervalItem.submenu = intervalMenu
        let activityItem = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        activityItem.target = self

        menu.items = [
            cpuItem,
            .separator(),
            runnerItem,
            showCPUItem,
            slowDownItem,
            flipItem,
            intervalItem,
            .separator(),
            launchAtLoginItem,
            activityItem,
            .separator(),
            NSMenuItem(title: "Quit RunCat Clone", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        cpuItem.title = String(format: "CPU: %.1f%%", cpuPercent)
        showCPUItem.state = settings.showsCPUUsage ? .on : .off
        slowDownItem.state = settings.speedDecreasesUnderLoad ? .on : .off
        flipItem.state = settings.isFlippedHorizontally ? .on : .off
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        for item in runnerMenu.items {
            item.state = item.representedObject as? String == settings.runnerID ? .on : .off
        }
        for item in intervalMenu.items {
            item.state = item.representedObject as? TimeInterval == settings.updateInterval ? .on : .off
        }
    }

    @objc private func selectRunner(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        settings.runnerID = id
        onChange?()
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? TimeInterval else { return }
        settings.updateInterval = interval
        onChange?()
    }

    @objc private func toggleShowCPU() {
        settings.showsCPUUsage.toggle()
        onChange?()
    }

    @objc private func toggleSlowDown() {
        settings.speedDecreasesUnderLoad.toggle()
        onChange?()
    }

    @objc private func toggleFlip() {
        settings.isFlippedHorizontally.toggle()
        onChange?()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }

    @objc private func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
}
