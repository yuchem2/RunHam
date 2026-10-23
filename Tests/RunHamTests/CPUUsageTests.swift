import Testing
@testable import RunHam

struct CPUUsageTests {
    @Test func ratioExcludesNiceFromUsage() {
        let old = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        let new = CPUTicks(user: 30, system: 20, idle: 40, nice: 10)
        #expect(CPUUsage.ratio(from: old, to: new) == 0.5)
    }

    @Test func ratioIsClampedBelowOne() {
        let old = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        let new = CPUTicks(user: 100, system: 0, idle: 0, nice: 0)
        #expect(CPUUsage.ratio(from: old, to: new) == 0.999)
    }

    @Test func ratioHandlesNoElapsedTicks() {
        let ticks = CPUTicks(user: 5, system: 5, idle: 5, nice: 5)
        #expect(CPUUsage.ratio(from: ticks, to: ticks) == 0)
    }

    @Test func ratioSurvivesCounterWrap() {
        let old = CPUTicks(user: .max, system: 0, idle: 0, nice: 0)
        let new = CPUTicks(user: 9, system: 0, idle: 10, nice: 0)
        #expect(CPUUsage.ratio(from: old, to: new) == 0.5)
    }

    @Test func percentRoundsToOneDecimal() {
        #expect(CPUUsage.percent(fromRatio: 0.12345) == 12.3)
        #expect(CPUUsage.percent(fromRatio: 0.999) == 99.9)
    }

    @Test func ringBufferAveragesMostRecentValues() {
        var buffer = RingBuffer(capacity: 3)
        for value in [1.0, 2, 3, 4, 5] { buffer.append(value) }
        #expect(buffer.average == 4)
    }
}
