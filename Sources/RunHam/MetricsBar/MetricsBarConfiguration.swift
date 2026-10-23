import Foundation

/// 메트릭스 바에 표시할 항목. 기본값은 CPU 만 켠다.
struct MetricsBarConfiguration: Codable, Equatable, Sendable {
    enum SystemMetric: String, CaseIterable, Sendable {
        case cpu, memory, storage, battery, network

        var title: String {
            switch self {
            case .cpu: L("metric.cpu")
            case .memory: L("metric.memory")
            case .storage: L("metric.storage")
            case .battery: L("metric.battery")
            case .network: L("metric.network")
            }
        }

        var symbol: String {
            switch self {
            case .cpu: "cpu"
            case .memory: "memorychip"
            case .storage: "internaldrive"
            case .battery: "battery.75percent"
            case .network: "network"
            }
        }
    }

    var showsCPU = true
    var showsMemory = false
    var showsStorage = false
    var showsBattery = false
    var showsNetwork = false
    var visibleCustomMetricsSourceIDs: Set<UUID> = []

    static let `default` = MetricsBarConfiguration()

    func shows(_ metric: SystemMetric) -> Bool {
        switch metric {
        case .cpu: showsCPU
        case .memory: showsMemory
        case .storage: showsStorage
        case .battery: showsBattery
        case .network: showsNetwork
        }
    }

    mutating func toggle(_ metric: SystemMetric) {
        switch metric {
        case .cpu: showsCPU.toggle()
        case .memory: showsMemory.toggle()
        case .storage: showsStorage.toggle()
        case .battery: showsBattery.toggle()
        case .network: showsNetwork.toggle()
        }
    }

    mutating func toggleCustomMetrics(_ id: UUID) {
        if visibleCustomMetricsSourceIDs.contains(id) {
            visibleCustomMetricsSourceIDs.remove(id)
        } else {
            visibleCustomMetricsSourceIDs.insert(id)
        }
    }
}
