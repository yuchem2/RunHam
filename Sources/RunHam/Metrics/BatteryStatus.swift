import Foundation
import IOKit

/// IORegistry `AppleSmartBattery` 에서 읽은 배터리 상태. 배터리가 없는 Mac 에선 nil.
struct BatteryStatus: Equatable, Sendable {
    /// 0...100
    var level: Int
    var isCharging: Bool
    var isPluggedIn: Bool
    var cycleCount: Int?
    /// 설계 용량 대비 현재 최대 용량(0...1)
    var health: Double?

    init(level: Int, isCharging: Bool, isPluggedIn: Bool, cycleCount: Int?, health: Double?) {
        self.level = level
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.cycleCount = cycleCount
        self.health = health
    }

    init?(properties: [String: Any]) {
        guard
            properties["BatteryInstalled"] as? Bool ?? true,
            let current = properties["CurrentCapacity"] as? Int,
            let max = properties["MaxCapacity"] as? Int, max > 0
        else { return nil }

        var health: Double?
        if let raw = properties["AppleRawMaxCapacity"] as? Int,
           let design = properties["DesignCapacity"] as? Int, design > 0 {
            health = min(1, Double(raw) / Double(design))
        }
        self.init(
            level: Int((Double(current) / Double(max) * 100).rounded()),
            isCharging: properties["IsCharging"] as? Bool ?? false,
            isPluggedIn: properties["ExternalConnected"] as? Bool ?? false,
            cycleCount: properties["CycleCount"] as? Int,
            health: health
        )
    }

    static func current() -> BatteryStatus? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard
            IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
            let properties = unmanaged?.takeRetainedValue() as? [String: Any]
        else { return nil }
        return BatteryStatus(properties: properties)
    }
}
