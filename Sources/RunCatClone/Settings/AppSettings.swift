import Foundation

/// UserDefaults 기반 설정. 키 이름은 원본 앱에서 관찰한 것(`SPEED_DECREASES_UNDER_LOAD` 등)을 따른다.
@MainActor
final class AppSettings {
    static let updateIntervals: [TimeInterval] = [1, 2, 3, 5]

    private enum Key {
        static let runnerID = "RUNNER_ID"
        static let speedDecreasesUnderLoad = "SPEED_DECREASES_UNDER_LOAD"
        static let isFlippedHorizontally = "IS_FLIPPED_HORIZONTALLY"
        static let showsCPUUsage = "SHOWS_CPU_USAGE"
        static let updateInterval = "UPDATE_INTERVAL"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.runnerID: "cat",
            Key.speedDecreasesUnderLoad: false,
            Key.isFlippedHorizontally: false,
            Key.showsCPUUsage: false,
            Key.updateInterval: 2.0,
        ])
    }

    var runnerID: String {
        get { defaults.string(forKey: Key.runnerID) ?? "cat" }
        set { defaults.set(newValue, forKey: Key.runnerID) }
    }

    var speedDecreasesUnderLoad: Bool {
        get { defaults.bool(forKey: Key.speedDecreasesUnderLoad) }
        set { defaults.set(newValue, forKey: Key.speedDecreasesUnderLoad) }
    }

    var isFlippedHorizontally: Bool {
        get { defaults.bool(forKey: Key.isFlippedHorizontally) }
        set { defaults.set(newValue, forKey: Key.isFlippedHorizontally) }
    }

    var showsCPUUsage: Bool {
        get { defaults.bool(forKey: Key.showsCPUUsage) }
        set { defaults.set(newValue, forKey: Key.showsCPUUsage) }
    }

    var updateInterval: TimeInterval {
        get {
            let value = defaults.double(forKey: Key.updateInterval)
            return Self.updateIntervals.contains(value) ? value : 2
        }
        set { defaults.set(newValue, forKey: Key.updateInterval) }
    }
}
