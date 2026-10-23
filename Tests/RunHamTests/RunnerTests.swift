import Testing
@testable import RunHam

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
        // 7프레임 갤럽이지만 한 보폭(속도 1)은 원본 5프레임 ÷ 초당 2프레임 = 2.5초와 같다.
        #expect(cat.frames.count == 7)
        #expect(cat.frames.allSatisfy { $0.width == 56 && $0.height == 36 })
        #expect(cat.pointSize == .init(width: 28, height: 18))
        #expect(abs(cat.cycleDuration - 2.5) < 0.0001)
        #expect(Runner.builtIn(id: "pixel-cat").cycleDuration == 2.5)
    }

    @Test func vectorCatIsSmoothAndHasHighResolutionPreview() {
        let cat = Runner.builtIn(id: "cat")
        #expect(!cat.isPixelArt)
        #expect(cat.previewFrames.count == cat.frames.count)
        #expect(cat.previewFrames.allSatisfy { $0.width == 168 && $0.height == 108 })
    }

    @Test func builtInRunnersAreSleekChubbyAndPixel() {
        #expect(Runner.builtIns.map(\.id) == ["cat", "chubby-cat", "pixel-cat"])
        let chubby = Runner.builtIn(id: "chubby-cat")
        #expect(!chubby.isPixelArt)
        #expect(chubby.frames.allSatisfy { $0.width == 56 && $0.height == 36 })
    }

    @Test func pixelCatStaysAvailable() {
        let pixel = Runner.builtIn(id: "pixel-cat")
        #expect(pixel.id == "pixel-cat")
        #expect(pixel.isPixelArt)
        #expect(pixel.frames.count == 5)
        #expect(pixel.pointSize == .init(width: 28, height: 18))
        // 없는 id 는 기본 러너(벡터 고양이)로
        #expect(Runner.builtIn(id: "unknown").id == "cat")
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
