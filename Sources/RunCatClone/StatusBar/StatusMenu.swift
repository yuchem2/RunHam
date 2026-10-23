import AppKit
import SwiftUI

/// 상태바 메뉴. 맨 위에 메트릭 대시보드를 두고, 아래에는 설정·바로가기만 둔다.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let dashboardItem = NSMenuItem()
    private let dashboardView: NSHostingView<DashboardView>

    var onOpenSettings: (() -> Void)?
    var onWillOpen: (() -> Void)?

    init(metrics: SystemMetrics, settings: AppSettings, customMetrics: CustomMetricsStore) {
        dashboardView = NSHostingView(rootView: DashboardView(metrics: metrics, settings: settings, customMetrics: customMetrics))
        super.init()
        menu.delegate = self
        dashboardItem.view = dashboardView
        resizeDashboard()

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        let activityItem = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        activityItem.target = self

        menu.items = [
            dashboardItem,
            .separator(),
            settingsItem,
            activityItem,
            .separator(),
            NSMenuItem(title: "Quit RunCat Clone", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]
    }

    // 카드 표시 설정이나 배터리 유무에 따라 높이가 달라지므로 열 때마다 맞춘다.
    func menuWillOpen(_ menu: NSMenu) {
        onWillOpen?()
        resizeDashboard()
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
