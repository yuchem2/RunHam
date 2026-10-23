import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let runnerView = RunnerStatusView()
    private let monitor = CPUMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            runnerView.frame = button.bounds
            runnerView.autoresizingMask = [.width, .height]
            button.addSubview(runnerView)
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item

        runnerView.setRunner(Runner.builtIn(id: "cat"), flipped: false)
        runnerView.showsCPU = true
        item.length = runnerView.preferredWidth

        monitor.onUpdate = { [weak self] percent in
            self?.cpuDidUpdate(percent)
        }
        monitor.start(interval: 2)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func cpuDidUpdate(_ percent: Double) {
        runnerView.cpuText = String(format: "%.1f%%", percent)
        runnerView.setSpeed(RunnerSpeed.speed(cpuPercent: percent, decreasesUnderLoad: false))
    }
}
