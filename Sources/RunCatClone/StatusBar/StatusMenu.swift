import AppKit
import SwiftUI

/// 상태바 메뉴. 맨 위에 메트릭 대시보드를 두고, 아래에는 설정·바로가기만 둔다.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let dashboardItem = NSMenuItem()
    private let settingsItem = NSMenuItem()
    private let activityItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private let dashboard: DashboardView
    /// 메뉴가 닫혀 있는 동안에는 빈 뷰로 바꿔 둔다. 그렇지 않으면 보이지 않는 대시보드가 측정값이 바뀔 때마다 다시 그려진다.
    private let dashboardView = NSHostingView(rootView: AnyView(EmptyView()))

    var onOpenSettings: (() -> Void)?
    var onWillOpen: (() -> Void)?

    init(metrics: SystemMetrics, settings: AppSettings, customMetrics: CustomMetricsStore) {
        dashboard = DashboardView(metrics: metrics, settings: settings, customMetrics: customMetrics)
        super.init()
        menu.delegate = self
        dashboardItem.view = dashboardView

        settingsItem.action = #selector(openSettings)
        settingsItem.keyEquivalent = ","
        settingsItem.target = self
        activityItem.action = #selector(openActivityMonitor)
        activityItem.target = self
        quitItem.action = #selector(NSApplication.terminate(_:))
        quitItem.keyEquivalent = "q"
        refreshTitles()

        menu.items = [
            dashboardItem,
            .separator(),
            settingsItem,
            activityItem,
            .separator(),
            quitItem,
        ]
    }

    // 카드 표시 설정이나 배터리 유무에 따라 높이가 달라지므로 열 때마다 맞춘다.
    func menuWillOpen(_ menu: NSMenu) {
        onWillOpen?()
        refreshTitles()
        dashboardView.rootView = AnyView(LocalizedRoot { dashboard })
        resizeDashboard()
    }

    func menuDidClose(_ menu: NSMenu) {
        dashboardView.rootView = AnyView(EmptyView())
    }

    /// 언어를 바꿔도 다음에 열 때 맞는 제목이 보이도록 열 때마다 다시 넣는다.
    private func refreshTitles() {
        settingsItem.title = L("menu.settings")
        activityItem.title = L("menu.activityMonitor")
        quitItem.title = L("menu.quit")
    }

    private func resizeDashboard() {
        dashboardView.layoutSubtreeIfNeeded()
        let size = dashboardView.fittingSize
        dashboardView.frame = CGRect(origin: .zero, size: CGSize(width: DashboardView.width, height: size.height))
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
