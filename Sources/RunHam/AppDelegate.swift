import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let settings = AppSettings()
    private let monitor = MetricsMonitor()
    private let customMetrics = CustomMetricsStore()
    private let customRunners = CustomRunnerStore()
    private lazy var statusMenu = StatusMenu(metrics: monitor.metrics, settings: settings, customMetrics: customMetrics)
    private lazy var metricsBar = MetricsBarController(settings: settings, metrics: monitor.metrics, customMetrics: customMetrics)
    private lazy var settingsWindow = SettingsWindowController(settings: settings, metrics: monitor.metrics, customMetrics: customMetrics, customRunners: customRunners)
    private lazy var licensesWindow = InfoWindowController(titleKey: "menu.licenses") { AnyView(LicensesView()) }
    private lazy var bugReportWindow = InfoWindowController(titleKey: "menu.bugReport") { [settings, customRunners] in
        AnyView(BugReportView(settings: settings, customRunners: customRunners))
    }
    private let runnerView = RunnerStatusView()
    private var appliedRunner: (id: String, flipped: Bool)?
    private var appliedInterval: TimeInterval?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            runnerView.frame = button.bounds
            runnerView.autoresizingMask = [.width, .height]
            button.addSubview(runnerView)
        }
        item.menu = statusMenu.menu
        statusItem = item

        statusMenu.onOpenSettings = { [weak self] in self?.settingsWindow.show() }
        statusMenu.onOpenLicenses = { [weak self] in self?.licensesWindow.show() }
        statusMenu.onOpenBugReport = { [weak self] in self?.bugReportWindow.show() }
        statusMenu.onWillOpen = { [weak self] in self?.monitor.refreshStorage() }
        metricsBar.onOpenSettings = { [weak self] in self?.settingsWindow.show() }
        settings.onChange = { [weak self] in self?.applySettings() }
        customRunners.onChange = { [weak self] in self?.customRunnersDidChange() }
        monitor.onCPUUpdate = { [weak self] percent in self?.cpuDidUpdate(percent) }
        applySettings()
        // 개발용: 실행하면서 PNG 프레임 폴더를 커스텀 러너로 추가하고 선택한다
        if let flag = CommandLine.arguments.firstIndex(of: "--import-runner"), flag + 1 < CommandLine.arguments.count {
            let folder = URL(fileURLWithPath: CommandLine.arguments[flag + 1])
            if let runner = try? customRunners.add(folder: folder) {
                settings.runnerID = runner.id
            }
        }
        // 개발용: 실행하자마자 설정 창을 연다(설정 창이 열린 상태의 CPU 측정 등)
        if CommandLine.arguments.contains("--open-settings") {
            settingsWindow.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func applySettings() {
        let runner = (id: settings.runnerID, flipped: settings.isFlippedHorizontally)
        if appliedRunner?.id != runner.id || appliedRunner?.flipped != runner.flipped {
            runnerView.setRunner(Runner.resolve(id: runner.id, custom: customRunners), flipped: runner.flipped)
            appliedRunner = runner
        }
        if appliedInterval != settings.updateInterval {
            monitor.start(interval: settings.updateInterval)
            appliedInterval = settings.updateInterval
        }
        runnerView.showsCPU = settings.showsCPUUsage
        statusItem?.length = runnerView.preferredWidth
        cpuDidUpdate(monitor.metrics.cpu.percent)
        metricsBar.update()
        settingsWindow.refreshTitles()
    }

    /// 커스텀 러너를 추가·삭제·수정하면 지금 러너를 다시 적용한다. 쓰던 러너를 지웠으면 기본 고양이로.
    private func customRunnersDidChange() {
        if settings.runnerID.hasPrefix(CustomRunnerStore.idPrefix), customRunners.runner(id: settings.runnerID) == nil {
            settings.runnerID = Runner.builtIns[0].id
        }
        appliedRunner = nil
        applySettings()
    }

    private func cpuDidUpdate(_ percent: Double) {
        runnerView.cpuText = String(format: "%.1f%%", percent)
        runnerView.setSpeed(RunnerSpeed.speed(cpuPercent: percent, decreasesUnderLoad: settings.speedDecreasesUnderLoad))
        metricsBar.update()
    }
}
