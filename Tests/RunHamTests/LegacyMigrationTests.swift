import Foundation
import Testing
@testable import RunHam

struct LegacyMigrationTests {
    @Test func copiesLegacySettingsOnceExceptSelectedRunner() {
        let legacyName = "RunHamTests.Legacy.\(UUID().uuidString)"
        let currentName = "RunHamTests.Current.\(UUID().uuidString)"
        let legacy = UserDefaults(suiteName: legacyName)!
        legacy.set("ko", forKey: "APP_LANGUAGE")
        legacy.set("custom-dolphin", forKey: "RUNNER_ID")
        legacy.set(true, forKey: "SHOWS_METRICS_BAR")
        let current = UserDefaults(suiteName: currentName)!
        current.set(false, forKey: "SHOWS_METRICS_BAR")
        defer {
            legacy.removePersistentDomain(forName: legacyName)
            current.removePersistentDomain(forName: currentName)
        }

        LegacyMigration.run(defaults: current, legacyDomain: legacyName, movesRunners: false)
        #expect(current.string(forKey: "APP_LANGUAGE") == "ko")
        // 이미 있는 값은 덮어쓰지 않고, 선택한 러너는 옮기지 않는다
        #expect(current.bool(forKey: "SHOWS_METRICS_BAR") == false)
        #expect(current.string(forKey: "RUNNER_ID") == nil)
        #expect(current.bool(forKey: LegacyMigration.doneKey))

        // 두 번째 실행은 아무것도 하지 않는다
        legacy.set("en", forKey: "UPDATE_INTERVAL_NAME")
        LegacyMigration.run(defaults: current, legacyDomain: legacyName, movesRunners: false)
        #expect(current.string(forKey: "UPDATE_INTERVAL_NAME") == nil)
    }
}
