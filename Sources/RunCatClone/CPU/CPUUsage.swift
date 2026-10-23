import Darwin

/// `host_cpu_load_info` 의 누적 tick 스냅샷.
struct CPUTicks: Equatable, Sendable {
    var user: UInt32
    var system: UInt32
    var idle: UInt32
    var nice: UInt32

    /// 시스템 전체 CPU 누적 tick 을 읽는다 (RunCat Neo 와 같은 HOST_CPU_LOAD_INFO 경로).
    static func current() -> CPUTicks? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return CPUTicks(
            user: info.cpu_ticks.0,
            system: info.cpu_ticks.1,
            idle: info.cpu_ticks.2,
            nice: info.cpu_ticks.3
        )
    }
}

enum CPUUsage {
    /// 원본과 동일한 상한값. 100% 로 표시되지 않도록 0.999 에서 자른다.
    static let maxRatio = 0.999

    /// 두 스냅샷 사이의 사용률(0...0.999). nice 는 분모에만 포함된다.
    static func ratio(from old: CPUTicks, to new: CPUTicks) -> Double {
        let user = Double(new.user &- old.user)
        let system = Double(new.system &- old.system)
        let idle = Double(new.idle &- old.idle)
        let nice = Double(new.nice &- old.nice)
        let total = user + system + idle + nice
        guard total > 0 else { return 0 }
        return min(user / total + system / total, maxRatio)
    }

    /// 소수점 한 자리 퍼센트. `round(ratio * 1000) / 10`
    static func percent(fromRatio ratio: Double) -> Double {
        (ratio * 1000).rounded() / 10
    }
}
