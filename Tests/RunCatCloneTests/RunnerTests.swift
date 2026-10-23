import Testing
@testable import RunCatClone

struct RunnerTests {
    @Test(arguments: [(0.0, 1.0), (4.9, 1.0), (50.0, 10.0), (99.9, 19.98), (150.0, 20.0)])
    func speedScalesWithCPU(percent: Double, expected: Float) {
        #expect(abs(RunnerSpeed.speed(cpuPercent: percent, decreasesUnderLoad: false) - expected) < 0.001)
    }

    @Test func slowDownUnderLoadInvertsRange() {
        #expect(RunnerSpeed.speed(cpuPercent: 0, decreasesUnderLoad: true) == 10)
        #expect(RunnerSpeed.speed(cpuPercent: 100, decreasesUnderLoad: true) == 0.5)
    }

    @Test func catSpriteMatchesOriginalFrameMetrics() {
        let cat = Runner.builtIn(id: "cat")
        #expect(cat.frames.count == 5)
        #expect(cat.frames.allSatisfy { $0.width == 56 && $0.height == 36 })
        #expect(cat.pointSize == .init(width: 28, height: 18))
        #expect(cat.cycleDuration == 2.5)
    }
}
