import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let settings = AppSettings()
    private let monitor = MetricsMonitor()
    private let customMetrics = CustomMetricsStore()
    private lazy var statusMenu = StatusMenu(metrics: monitor.metrics, settings: settings, customMetrics: customMetrics)
    private lazy var metricsBar = MetricsBarController(settings: settings, metrics: monitor.metrics, customMetrics: customMetrics)
    private lazy var settingsWindow = SettingsWindowController(settings: settings, metrics: monitor.metrics, customMetrics: customMetrics)
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
        statusMenu.onWillOpen = { [weak self] in self?.monitor.refreshStorage() }
        metricsBar.onOpenSettings = { [weak self] in self?.settingsWindow.show() }
        settings.onChange = { [weak self] in self?.applySettings() }
        monitor.onCPUUpdate = { [weak self] percent in self?.cpuDidUpdate(percent) }
        applySettings()
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
            runnerView.setRunner(Runner.builtIn(id: runner.id), flipped: runner.flipped)
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

    private func cpuDidUpdate(_ percent: Double) {
        runnerView.cpuText = String(format: "%.1f%%", percent)
        runnerView.setSpeed(RunnerSpeed.speed(cpuPercent: percent, decreasesUnderLoad: settings.speedDecreasesUnderLoad))
        metricsBar.update()
    }
}
