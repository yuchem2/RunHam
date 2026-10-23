import AppKit
import SwiftUI

/// 상태바 메뉴. 메트릭 대시보드 하나만 두고, 설정·활성 상태 보기·종료는 대시보드 맨 위 햄버거 버튼에서 연다.
/// ⌘, 와 ⌘Q 는 숨긴 메뉴 항목으로 그대로 쓸 수 있다.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let dashboardItem = NSMenuItem()
    private let settingsItem = NSMenuItem()
    private let activityItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private let dashboard: DashboardView
    private let header = DashboardHeaderModel()
    /// 메뉴가 닫혀 있는 동안에는 빈 뷰로 바꿔 둔다. 그렇지 않으면 보이지 않는 대시보드가 측정값이 바뀔 때마다 다시 그려진다.
    private let dashboardView = NSHostingView(rootView: AnyView(EmptyView()))

    var onOpenSettings: (() -> Void)?
    var onWillOpen: (() -> Void)?

    init(metrics: SystemMetrics, settings: AppSettings, customMetrics: CustomMetricsStore) {
        dashboard = DashboardView(metrics: metrics, settings: settings, customMetrics: customMetrics, header: header)
        super.init()
        // 메뉴를 먼저 닫고 나서 실행해야 설정 창이 메뉴 뒤로 숨지 않는다
        header.items = [
            .init(symbol: "info.circle", key: "menu.about") { [weak self] in
                self?.closeMenu { Self.showAbout() }
            },
            .init(symbol: "gearshape", key: "menu.settings", shortcut: "⌘,", startsGroup: true) { [weak self] in
                self?.closeMenu { self?.onOpenSettings?() }
            },
            .init(symbol: "waveform.path.ecg.rectangle", key: "menu.activityMonitor") { [weak self] in
                self?.closeMenu { self?.openActivityMonitor() }
            },
            .init(symbol: "power", key: "menu.quit", shortcut: "⌘Q", startsGroup: true) { [weak self] in
                self?.closeMenu { NSApp.terminate(nil) }
            },
        ]
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

        for item in [settingsItem, activityItem, quitItem] {
            item.isHidden = true
            item.allowsKeyEquivalentWhenHidden = true
        }
        menu.items = [dashboardItem, settingsItem, activityItem, quitItem]
    }

    private func closeMenu(then action: @escaping @MainActor () -> Void) {
        menu.cancelTracking()
        DispatchQueue.main.async { action() }
    }

    // 카드 표시 설정이나 배터리 유무에 따라 높이가 달라지므로 열 때마다 맞춘다.
    func menuWillOpen(_ menu: NSMenu) {
        onWillOpen?()
        header.isExpanded = false
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

    /// macOS 기본 정보 창: 앱 아이콘·이름·버전에 라이선스 문구를 붙인다
    static func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationIcon: NSImage(cgImage: AppIconRenderer.render(pixels: 256), size: NSSize(width: 128, height: 128)),
            .credits: NSAttributedString(
                string: L("about.credit"),
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: NSColor.secondaryLabelColor]
            ),
        ])
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
