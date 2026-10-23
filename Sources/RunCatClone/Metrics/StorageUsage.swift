import Foundation

/// 시동 디스크 용량. 가용량은 Finder 와 같이 "중요한 용도로 사용 가능" 값을 쓴다(정리 가능 공간 포함).
struct StorageUsage: Equatable, Sendable {
    var total: Int64
    var available: Int64

    var used: Int64 { max(0, total - available) }

    var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }

    static func current(volume: URL = URL(fileURLWithPath: "/")) -> StorageUsage? {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard
            let values = try? volume.resourceValues(forKeys: keys),
            let total = values.volumeTotalCapacity,
            let available = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return StorageUsage(total: Int64(total), available: available)
    }
}
