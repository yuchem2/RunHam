import AppKit
import SwiftUI

/// macOS 기본 설정 창처럼 툴바 탭(아이콘 + 이름)을 쓰는 설정 창. 처음 열 때 만들고 이후엔 재사용한다.
@MainActor
final class SettingsWindowController {
    private let settings: AppSettings
    private let metrics: SystemMetrics
    private let customMetrics: CustomMetricsStore
    private let launchAtLogin = LaunchAtLogin()
    private var window: NSWindow?

    init(settings: AppSettings, metrics: SystemMetrics, customMetrics: CustomMetricsStore) {
        self.settings = settings
        self.metrics = metrics
        self.customMetrics = customMetrics
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        // 메뉴바 전용(accessory) 앱이라 창을 앞으로 가져오려면 앱을 활성화해야 한다.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        // 탭 이름이 창 제목이 된다.
        tabs.canPropagateSelectedChildViewControllerTitle = true
        addTab(to: tabs, title: "General", symbol: "gearshape",
               view: GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin))
        addTab(to: tabs, title: "Runner", symbol: "cat",
               view: RunnerSettingsView(settings: settings, metrics: metrics))
        addTab(to: tabs, title: "Metrics", symbol: "gauge.with.dots.needle.33percent",
               view: MetricsSettingsView(settings: settings, customMetrics: customMetrics))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func addTab(to tabs: NSTabViewController, title: String, symbol: String, view: some View) {
        let controller = NSHostingController(rootView: view)
        controller.sizingOptions = [.preferredContentSize]
        controller.title = title
        let item = NSTabViewItem(viewController: controller)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        tabs.addTabViewItem(item)
    }
}
