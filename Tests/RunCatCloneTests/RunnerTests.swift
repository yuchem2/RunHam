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

struct PixelArtTests {
    @Test func stampHandlesSolidShadeAndHoles() {
        var canvas = PixelCanvas(width: 3, height: 1)
        canvas.stamp(PixelSprite(["###"]), x: 0, y: 0)
        canvas.stamp(PixelSprite(["o+."]), x: 0, y: 0)
        #expect(canvas[0, 0] == 0)
        #expect(canvas[1, 0] == PixelCanvas.shade)
        #expect(canvas[2, 0] == PixelCanvas.solid)
    }

    @Test func stampClipsOutsideCanvas() {
        var canvas = PixelCanvas(width: 2, height: 2)
        canvas.stamp(PixelSprite(["###", "###"]), x: 1, y: 1)
        #expect(canvas.alpha == [0, 0, 0, 1])
    }

    @Test func imageIsNearestNeighborScaled() {
        var canvas = PixelCanvas(width: 2, height: 1)
        canvas[0, 0] = 1
        let image = canvas.makeImage(scale: 2)
        #expect(image.width == 4 && image.height == 2)
    }
}
