import AppKit
import SwiftUI

/// 설정 창. 처음 열 때 만들고 이후엔 재사용한다.
@MainActor
final class SettingsWindowController {
    private let settings: AppSettings
    private let launchAtLogin = LaunchAtLogin()
    private var window: NSWindow?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        // 메뉴바 전용(accessory) 앱이라 창을 앞으로 가져오려면 앱을 활성화해야 한다.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let controller = NSHostingController(rootView: SettingsView(settings: settings, launchAtLogin: launchAtLogin))
        controller.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: controller)
        window.title = "RunCat Clone Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
