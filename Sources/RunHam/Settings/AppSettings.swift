import Foundation
import Observation

/// UserDefaults 기반 설정. 키 이름은 원본 앱에서 관찰한 것(`SPEED_DECREASES_UNDER_LOAD` 등)을 따른다.
/// 설정 창(SwiftUI)이 직접 바인딩하고, 값이 바뀌면 `onChange` 로 앱에 알린다.
@MainActor
@Observable
final class AppSettings {
    static let updateIntervals: [TimeInterval] = [1, 2, 3, 5]

    private enum Key {
        static let runnerID = "RUNNER_ID"
        static let speedDecreasesUnderLoad = "SPEED_DECREASES_UNDER_LOAD"
        static let isFlippedHorizontally = "IS_FLIPPED_HORIZONTALLY"
        static let showsCPUUsage = "SHOWS_CPU_USAGE"
        static let updateInterval = "UPDATE_INTERVAL"
        static let showsMemory = "SHOWS_MEMORY_METRICS"
        static let showsStorage = "SHOWS_STORAGE_METRICS"
        static let showsBattery = "SHOWS_BATTERY_METRICS"
        static let showsNetwork = "SHOWS_NETWORK_METRICS"
        static let showsMetricsBar = "SHOWS_METRICS_BAR"
        static let metricsBar = "METRICS_BAR_CONFIGURATION"
        static let language = "APP_LANGUAGE"
        static let metricsBarNoticeSuppressed = "METRICS_BAR_NOTICE_SUPPRESSED"
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored var onChange: (() -> Void)?

    var runnerID: String {
        didSet { save(runnerID, Key.runnerID) }
    }

    var speedDecreasesUnderLoad: Bool {
        didSet { save(speedDecreasesUnderLoad, Key.speedDecreasesUnderLoad) }
    }

    var isFlippedHorizontally: Bool {
        didSet { save(isFlippedHorizontally, Key.isFlippedHorizontally) }
    }

    var showsCPUUsage: Bool {
        didSet { save(showsCPUUsage, Key.showsCPUUsage) }
    }

    var updateInterval: TimeInterval {
        didSet {
            if !Self.updateIntervals.contains(updateInterval) {
                updateInterval = 2
                return
            }
            save(updateInterval, Key.updateInterval)
        }
    }

    var showsMemory: Bool {
        didSet { save(showsMemory, Key.showsMemory) }
    }

    var showsStorage: Bool {
        didSet { save(showsStorage, Key.showsStorage) }
    }

    var showsBattery: Bool {
        didSet { save(showsBattery, Key.showsBattery) }
    }

    var showsNetwork: Bool {
        didSet { save(showsNetwork, Key.showsNetwork) }
    }

    /// 메뉴바에 수치를 상시 표시하는 메트릭스 바 사용 여부(기본 꺼짐)
    var showsMetricsBar: Bool {
        didSet { save(showsMetricsBar, Key.showsMetricsBar) }
    }

    var metricsBar: MetricsBarConfiguration {
        didSet { save((try? JSONEncoder().encode(metricsBar)) ?? Data(), Key.metricsBar) }
    }

    /// 메트릭스 바를 켤 때 노치 안내를 다시 보지 않기로 했는지
    var metricsBarNoticeSuppressed: Bool {
        didSet { save(metricsBarNoticeSuppressed, Key.metricsBarNoticeSuppressed) }
    }

    /// 표시 언어. 바꾸면 재시작 없이 바로 적용된다.
    var language: AppLanguage {
        didSet {
            Localization.shared.language = language
            save(language.storageValue, Key.language)
        }
    }

    /// 설정 창 미리보기 속도. 저장하지 않는다(원본의 `previewSpeed` 와 같은 역할).
    var previewSpeed: Double = 1
    /// 미리보기가 현재 CPU 기준 속도(메뉴바와 같은 속도)를 따를지 여부. 저장하지 않는다.
    var previewFollowsCPU = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.runnerID: "cat",
            Key.speedDecreasesUnderLoad: false,
            Key.isFlippedHorizontally: false,
            Key.showsCPUUsage: false,
            Key.updateInterval: 2.0,
            Key.showsMemory: true,
            Key.showsStorage: true,
            Key.showsBattery: true,
            Key.showsNetwork: true,
            Key.showsMetricsBar: false,
        ])
        runnerID = defaults.string(forKey: Key.runnerID) ?? "cat"
        speedDecreasesUnderLoad = defaults.bool(forKey: Key.speedDecreasesUnderLoad)
        isFlippedHorizontally = defaults.bool(forKey: Key.isFlippedHorizontally)
        showsCPUUsage = defaults.bool(forKey: Key.showsCPUUsage)
        let interval = defaults.double(forKey: Key.updateInterval)
        updateInterval = Self.updateIntervals.contains(interval) ? interval : 2
        showsMemory = defaults.bool(forKey: Key.showsMemory)
        showsStorage = defaults.bool(forKey: Key.showsStorage)
        showsBattery = defaults.bool(forKey: Key.showsBattery)
        showsNetwork = defaults.bool(forKey: Key.showsNetwork)
        showsMetricsBar = defaults.bool(forKey: Key.showsMetricsBar)
        metricsBarNoticeSuppressed = defaults.bool(forKey: Key.metricsBarNoticeSuppressed)
        language = AppLanguage(storageValue: defaults.string(forKey: Key.language) ?? AppLanguage.system.storageValue)
        metricsBar = defaults.data(forKey: Key.metricsBar)
            .flatMap { try? JSONDecoder().decode(MetricsBarConfiguration.self, from: $0) } ?? .default
        Localization.shared.language = language
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
