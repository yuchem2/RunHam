import AppKit
import SwiftUI

/// macOS 기본 설정 창처럼 툴바 탭(아이콘 + 이름)을 쓰는 설정 창. 처음 열 때 만들고 이후엔 재사용한다.
@MainActor
final class SettingsWindowController {
    private let settings: AppSettings
    private let metrics: SystemMetrics
    private let customMetrics: CustomMetricsStore
    private let customRunners: CustomRunnerStore
    private let launchAtLogin = LaunchAtLogin()
    private var window: NSWindow?
    private var tabItems: [NSTabViewItem] = []
    private var closeObserver: NSObjectProtocol?

    init(settings: AppSettings, metrics: SystemMetrics, customMetrics: CustomMetricsStore, customRunners: CustomRunnerStore) {
        self.settings = settings
        self.metrics = metrics
        self.customMetrics = customMetrics
        self.customRunners = customRunners
    }

    func show() {
        let window: NSWindow
        if let existing = self.window {
            window = existing
        } else {
            window = makeWindow()
            self.window = window
            // 닫으면 창과 SwiftUI 화면을 통째로 버려, 보이지 않는 동안 아무 일도 하지 않게 한다.
            closeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.releaseWindow() }
            }
        }
        // 메뉴바 전용(accessory) 앱이라 창을 앞으로 가져오려면 앱을 활성화해야 한다.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func releaseWindow() {
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
        }
        closeObserver = nil
        window?.contentViewController = nil
        window = nil
        tabItems = []
    }

    private func makeWindow() -> NSWindow {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        // 탭 이름이 창 제목이 된다.
        tabs.canPropagateSelectedChildViewControllerTitle = true
        addTab(to: tabs, key: "settings.tab.general", image: symbol("gearshape"),
               view: GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin))
        addTab(to: tabs, key: "settings.tab.runner", image: HamsterSymbol.toolbarImage,
               view: RunnerSettingsView(settings: settings, metrics: metrics, customRunners: customRunners))
        addTab(to: tabs, key: "settings.tab.metrics", image: symbol("gauge.with.dots.needle.33percent"),
               view: MetricsSettingsView(settings: settings, customMetrics: customMetrics))
        // 설정을 열면 가장 자주 바꾸는 러너 탭부터 보여 준다.
        // 창에 붙기 전에는 tabs.tabView 가 비어 있으므로 tabViewItems 에서 찾는다.
        if let runner = tabs.tabViewItems.firstIndex(where: { $0.identifier as? String == "settings.tab.runner" }) {
            tabs.selectedTabViewItemIndex = runner
        }

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        // 탭을 바꾸며 창 크기가 변할 때 내용 밖이 회색으로 비치지 않게 내용과 같은 배경색을 쓴다.
        window.backgroundColor = .textBackgroundColor
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    private func addTab(to tabs: NSTabViewController, key: String, image: NSImage?, view: some View) {
        let controller = NSHostingController(rootView: LocalizedRoot { view })
        controller.sizingOptions = [.preferredContentSize]
        let item = NSTabViewItem(viewController: controller)
        item.identifier = key
        item.image = image
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
