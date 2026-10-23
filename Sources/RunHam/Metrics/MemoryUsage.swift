import Darwin
import Foundation

/// Activity Monitor 의 "사용된 메모리" 와 같은 방식(앱 + 와이어드 + 압축)으로 계산한 메모리 사용량.
struct MemoryUsage: Equatable, Sendable {
    var total: UInt64
    var app: UInt64
    var wired: UInt64
    var compressed: UInt64

    var used: UInt64 { app + wired + compressed }

    /// 사용 비율. 꽉 찼을 때 100% 로 보이지 않도록 0.999 에서 자른다.
    var ratio: Double {
        guard total > 0 else { return 0 }
        return min(Double(used) / Double(total), CPUUsage.maxRatio)
    }

    struct Pages: Sendable {
        var active: UInt64
        var inactive: UInt64
        var speculative: UInt64
        var purgeable: UInt64
        var external: UInt64
        var wired: UInt64
        var compressed: UInt64
    }

    init(total: UInt64, app: UInt64, wired: UInt64, compressed: UInt64) {
        self.total = total
        self.app = app
        self.wired = wired
        self.compressed = compressed
    }

    init(pages: Pages, pageSize: UInt64, total: UInt64) {
        let cached = pages.purgeable + pages.external
        let appPages = pages.active + pages.inactive + pages.speculative
        self.init(
            total: total,
            app: (appPages > cached ? appPages - cached : 0) * pageSize,
            wired: pages.wired * pageSize,
            compressed: pages.compressed * pageSize
        )
    }

    static func current() -> MemoryUsage? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        let pages = Pages(
            active: UInt64(stats.active_count),
            inactive: UInt64(stats.inactive_count),
            speculative: UInt64(stats.speculative_count),
            purgeable: UInt64(stats.purgeable_count),
            external: UInt64(stats.external_page_count),
            wired: UInt64(stats.wire_count),
            compressed: UInt64(stats.compressor_page_count)
        )
        return MemoryUsage(pages: pages, pageSize: UInt64(pageSize), total: ProcessInfo.processInfo.physicalMemory)
    }
}
