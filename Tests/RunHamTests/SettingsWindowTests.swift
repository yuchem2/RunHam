import AppKit
import Foundation
import Testing
@testable import RunHam

@MainActor
struct SettingsWindowTests {
    /// 설정 창을 실제로 만들어 연다. 처음 보이는 탭이 러너인지, 여는 동안 앱이 죽지 않는지 확인한다.
    @Test func opensOnRunnerTab() throws {
        _ = NSApplication.shared
        let suite = "RunHamTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let controller = SettingsWindowController(
            settings: AppSettings(defaults: defaults),
            metrics: SystemMetrics(),
            customMetrics: CustomMetricsStore(defaults: defaults),
            customRunners: CustomRunnerStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(suite))
        )
        controller.show()
        let window = try #require(NSApp.windows.first { $0.contentViewController is NSTabViewController })
        defer { window.close() }
        let tabs = try #require(window.contentViewController as? NSTabViewController)
        #expect(tabs.tabViewItems[tabs.selectedTabViewItemIndex].identifier as? String == "settings.tab.runner")
    }
}
