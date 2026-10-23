import Foundation
import Network
import Observation

/// 대시보드가 그리는 최신 측정값. 메인 스레드에서만 갱신한다.
@MainActor
@Observable
final class SystemMetrics {
    static let historyLength = 40

    var cpu = CPUSnapshot.zero
    /// 최근 CPU 사용률(퍼센트), 오래된 것부터.
    var cpuHistory: [Double] = []
    var memory: MemoryUsage?
    var storage: StorageUsage?
    var battery: BatteryStatus?
    var throughput = NetworkThroughput.zero
    var isNetworkConnected = false
    var networkInterface: String?
    var lastUpdated: Date?

    func appendCPU(_ snapshot: CPUSnapshot) {
        cpu = snapshot
        cpuHistory.append(snapshot.percent)
        if cpuHistory.count > Self.historyLength {
            cpuHistory.removeFirst(cpuHistory.count - Self.historyLength)
        }
    }
}

/// 하나의 타이머로 CPU·메모리·저장공간·배터리·네트워크를 함께 샘플링한다.
@MainActor
final class MetricsMonitor {
    let metrics = SystemMetrics()
    var onCPUUpdate: ((Double) -> Void)?

    /// 저장공간 가용량 조회(`volumeAvailableCapacityForImportantUsage`)는 CacheDelete 를 거쳐 비싸므로 드물게 갱신한다.
    static let storageRefreshInterval: TimeInterval = 60

    private var cpuSampler = CPUSampler()
    private var lastStorageRefresh: Date?
    private var lastNetwork: (counters: NetworkCounters, time: Date)?
    private var timer: Timer?
    private let pathMonitor = NWPathMonitor()

    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let interface = Self.interfaceName(for: path)
            MainActor.assumeIsolated {
                self?.metrics.isNetworkConnected = connected
                self?.metrics.networkInterface = interface
            }
        }
        pathMonitor.start(queue: .main)
    }

    func start(interval: TimeInterval) {
        stop()
        sample()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        timer.tolerance = interval * 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func sample() {
        let now = Date()
        if let ticks = CPUTicks.current(), let snapshot = cpuSampler.sample(ticks) {
            metrics.appendCPU(snapshot)
            onCPUUpdate?(snapshot.percent)
        }
        metrics.memory = MemoryUsage.current()
        if lastStorageRefresh.map({ now.timeIntervalSince($0) >= Self.storageRefreshInterval }) ?? true {
            refreshStorage()
        }
        metrics.battery = BatteryStatus.current()
        if let counters = NetworkCounters.current() {
            if let last = lastNetwork {
                metrics.throughput = NetworkThroughput(from: last.counters, to: counters, interval: now.timeIntervalSince(last.time))
            }
            lastNetwork = (counters, now)
        }
        metrics.lastUpdated = now
    }

    func refreshStorage() {
        metrics.storage = StorageUsage.current()
        lastStorageRefresh = Date()
    }

    private nonisolated static func interfaceName(for path: NWPath) -> String? {
        if path.usesInterfaceType(.wifi) { return "Wi-Fi" }
        if path.usesInterfaceType(.wiredEthernet) { return "Ethernet" }
        if path.usesInterfaceType(.cellular) { return "Cellular" }
        if path.status == .satisfied { return path.availableInterfaces.first?.name }
        return nil
    }
}
