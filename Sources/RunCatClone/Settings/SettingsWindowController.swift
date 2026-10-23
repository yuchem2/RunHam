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
    private var tabItems: [NSTabViewItem] = []

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
        addTab(to: tabs, key: "settings.tab.general", symbol: "gearshape",
               view: GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin))
        addTab(to: tabs, key: "settings.tab.runner", symbol: "cat",
               view: RunnerSettingsView(settings: settings, metrics: metrics))
        addTab(to: tabs, key: "settings.tab.metrics", symbol: "gauge.with.dots.needle.33percent",
               view: MetricsSettingsView(settings: settings, customMetrics: customMetrics))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        // 탭을 바꾸며 창 크기가 변할 때 내용 밖이 회색으로 비치지 않게 내용과 같은 배경색을 쓴다.
        window.backgroundColor = .textBackgroundColor
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func addTab(to tabs: NSTabViewController, key: String, symbol: String, view: some View) {
        let controller = NSHostingController(rootView: LocalizedRoot { view })
        controller.sizingOptions = [.preferredContentSize]
        let item = NSTabViewItem(viewController: controller)
        item.identifier = key
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        tabs.addTabViewItem(item)
        tabItems.append(item)
        refreshTitles()
    }

    /// 탭 이름과 창 제목을 현재 언어로 맞춘다. SwiftUI 내용은 LocalizedRoot 가 알아서 다시 그린다.
    func refreshTitles() {
        for item in tabItems {
            guard let key = item.identifier as? String else { continue }
            item.label = L(key)
            item.viewController?.title = L(key)
        }
        if let tabs = window?.contentViewController as? NSTabViewController {
            window?.title = tabs.tabViewItems[tabs.selectedTabViewItemIndex].label
        }
    }
}
