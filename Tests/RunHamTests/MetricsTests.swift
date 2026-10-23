import Testing
@testable import RunHam

struct MetricsTests {
    @Test func cpuSamplerNeedsBaselineThenAverages() {
        var sampler = CPUSampler(bufferSize: 2)
        #expect(sampler.sample(CPUTicks(user: 0, system: 0, idle: 0, nice: 0)) == nil)
        let first = sampler.sample(CPUTicks(user: 30, system: 20, idle: 50, nice: 0))
        #expect(first?.percent == 50)
        #expect(first?.user == 30)
        #expect(first?.system == 20)
        #expect(first?.idle == 50)
        let second = sampler.sample(CPUTicks(user: 30, system: 20, idle: 150, nice: 0))
        #expect(second?.percent == 25)
    }

    @Test func memoryExcludesCachedPagesFromAppMemory() {
        let pages = MemoryUsage.Pages(
            active: 100, inactive: 50, speculative: 10,
            purgeable: 20, external: 40, wired: 30, compressed: 10
        )
        let memory = MemoryUsage(pages: pages, pageSize: 16_384, total: 400 * 16_384)
        #expect(memory.app == 100 * 16_384)
        #expect(memory.used == 140 * 16_384)
        #expect(memory.ratio == 0.35)
    }

    @Test func memoryRatioIsClamped() {
        let memory = MemoryUsage(total: 100, app: 100, wired: 50, compressed: 0)
        #expect(memory.ratio == 0.999)
    }

    @Test func storageRatioUsesAvailableCapacity() {
        let storage = StorageUsage(total: 1000, available: 250)
        #expect(storage.used == 750)
        #expect(storage.ratio == 0.75)
    }

    @Test func batteryParsesRegistryProperties() {
        let battery = BatteryStatus(properties: [
            "CurrentCapacity": 81, "MaxCapacity": 100, "IsCharging": true, "ExternalConnected": true,
            "CycleCount": 120, "AppleRawMaxCapacity": 4500, "DesignCapacity": 5000,
        ])
        #expect(battery == BatteryStatus(level: 81, isCharging: true, isPluggedIn: true, cycleCount: 120, health: 0.9))
    }

    @Test func batteryIsNilWhenNotInstalled() {
        #expect(BatteryStatus(properties: ["BatteryInstalled": false, "CurrentCapacity": 0, "MaxCapacity": 100]) == nil)
    }

    @Test func throughputIsBytesPerSecond() {
        let old = NetworkCounters(received: 1_000, sent: 500)
        let new = NetworkCounters(received: 5_000, sent: 700)
        #expect(NetworkThroughput(from: old, to: new, interval: 2) == NetworkThroughput(received: 2_000, sent: 100))
    }

    @Test func throughputIgnoresCounterDrops() {
        let old = NetworkCounters(received: 5_000, sent: 500)
        let new = NetworkCounters(received: 1_000, sent: 700)
        #expect(NetworkThroughput(from: old, to: new, interval: 1) == NetworkThroughput(received: 0, sent: 200))
    }

    @Test func liveReadersReturnValues() {
        #expect(CPUTicks.current() != nil)
        #expect((MemoryUsage.current()?.total ?? 0) > 0)
        #expect((StorageUsage.current()?.total ?? 0) > 0)
        #expect(NetworkCounters.current() != nil)
    }
}

struct NetworkAddressTests {
    @Test func loopbackHasIPv4() {
        #expect(NetworkAddresses.current(interface: "lo0").ipv4 == "127.0.0.1")
    }

    @Test func unknownInterfaceHasNoAddress() {
        #expect(NetworkAddresses.current(interface: "does-not-exist0") == NetworkAddresses())
    }
}
