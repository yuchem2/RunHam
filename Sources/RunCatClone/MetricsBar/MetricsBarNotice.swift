import AppKit

/// 메트릭스 바를 켤 때 노치 주의사항을 보여 준다(원본의 "Notes on using Metrics Bar" 와 같은 흐름).
/// 노치가 있는 화면이 연결돼 있을 때만, 그리고 "다시 표시하지 않음" 을 고르지 않았을 때만 묻는다.
@MainActor
enum MetricsBarNotice {
    static var hasNotchedScreen: Bool {
        NSScreen.screens.contains { $0.safeAreaInsets.top > 0 }
    }

    static func confirmEnabling(settings: AppSettings) {
        guard hasNotchedScreen, !settings.metricsBarNoticeSuppressed else {
            settings.showsMetricsBar = true
            return
        }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L("metricsBar.notice.title")
        alert.informativeText = L("settings.metricsBar.notch")
        alert.addButton(withTitle: L("common.show"))
        alert.addButton(withTitle: L("common.cancel"))
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = L("common.dontShowAgain")

        let finish: (NSApplication.ModalResponse) -> Void = { response in
            if alert.suppressionButton?.state == .on {
                settings.metricsBarNoticeSuppressed = true
            }
            // "취소" 를 고르면 켜지 않는다.
            settings.showsMetricsBar = response == .alertFirstButtonReturn
        }
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(alert.runModal())
        }
    }
}
