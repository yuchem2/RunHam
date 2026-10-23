import Foundation
import Testing
@testable import RunHam

@MainActor
struct AppSettingsTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "RunHamTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultsMatchFirstLaunch() {
        let settings = AppSettings(defaults: makeDefaults())
        #expect(settings.runnerID == "cat")
        #expect(settings.speedDecreasesUnderLoad == false)
        #expect(settings.isFlippedHorizontally == false)
        #expect(settings.showsCPUUsage == false)
        #expect(settings.updateInterval == 2)
    }

    @Test func persistsChanges() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.speedDecreasesUnderLoad = true
        settings.updateInterval = 5
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.speedDecreasesUnderLoad)
        #expect(reloaded.updateInterval == 5)
    }

    @Test func rejectsUnsupportedInterval() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.updateInterval = 7
        #expect(settings.updateInterval == 2)
    }
}
