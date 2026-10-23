import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let settings = AppSettings()
    private lazy var statusMenu = StatusMenu(settings: settings)
    private let runnerView = RunnerStatusView()
    private let monitor = MetricsMonitor()
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

        statusMenu.onChange = { [weak self] in self?.applySettings() }
        monitor.onCPUUpdate = { [weak self] percent in self?.cpuDidUpdate(percent) }
        applySettings()
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
    }

    private func cpuDidUpdate(_ percent: Double) {
        statusMenu.cpuPercent = percent
        runnerView.cpuText = String(format: "%.1f%%", percent)
        runnerView.setSpeed(RunnerSpeed.speed(cpuPercent: percent, decreasesUnderLoad: settings.speedDecreasesUnderLoad))
    }
}
