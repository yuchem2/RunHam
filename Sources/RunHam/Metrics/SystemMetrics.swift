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
    /// 현재 경로의 BSD 인터페이스 이름(en0 등)
    var networkBSDName: String?
    var addresses = NetworkAddresses()
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
            let bsdName = connected ? path.availableInterfaces.first?.name : nil
            MainActor.assumeIsolated {
                self?.metrics.isNetworkConnected = connected
                self?.metrics.networkInterface = interface
                self?.metrics.networkBSDName = bsdName
                self?.refreshAddresses()
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
        refreshAddresses()
        metrics.lastUpdated = now
    }

    /// DHCP 갱신 등으로 경로 변경 없이 주소만 바뀔 수 있어 샘플마다 다시 읽는다(getifaddrs 라 가볍다).
    func refreshAddresses() {
        metrics.addresses = metrics.networkBSDName.map(NetworkAddresses.current(interface:)) ?? NetworkAddresses()
    }

    func refreshStorage() {
        metrics.storage = StorageUsage.current()
        lastStorageRefresh = Date()
    }

    private nonisolated static func interfaceName(for path: NWPath) -> String? {
        // 표시 이름은 언어에 따라 바뀌므로 식별자만 저장하고 Format.interfaceName 에서 바꾼다.
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.wiredEthernet) { return "ethernet" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        if path.status == .satisfied { return path.availableInterfaces.first?.name }
        return nil
    }
}
