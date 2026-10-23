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

    @Test func catSpriteMetrics() {
        let cat = Runner.builtIn(id: "cat")
        // 8프레임 한 보폭이 속도 1 에서 2.5초
        #expect(cat.frames.count == 8)
        #expect(cat.frames.allSatisfy { $0.width == 56 && $0.height == 36 })
        #expect(cat.pointSize == .init(width: 28, height: 18))
        #expect(abs(cat.cycleDuration - 2.5) < 0.0001)
    }

    @Test func vectorRunnersHaveHighResolutionPreview() {
        for runner in Runner.builtIns {
            #expect(!runner.isPixelArt)
            #expect(runner.previewFrames.count == runner.frames.count)
            #expect(runner.previewFrames.allSatisfy { $0.height == 108 && $0.width == $0.height * runner.frames[0].width / 36 })
        }
    }

    @Test func builtInRunners() {
        #expect(Runner.builtIns.map(\.id) == [
            "hamster", "hamster-ball", "hamster-snack", "hamster-roll", "hamster-cheeks",
            "cat", "chick", "penguin", "whale", "shark",
        ])
        // 모든 기본 러너는 메뉴바 높이(18pt)를 쓰고 이름이 번역돼 있다
        #expect(Runner.builtIns.allSatisfy { $0.pointSize.height == 18 && $0.name != $0.nameKey })
        let hamster = Runner.builtIn(id: "hamster")
        #expect(hamster.frames.count == 8)
        #expect(hamster.pointSize == .init(width: 22, height: 18))
        #expect(abs(hamster.cycleDuration - 2) < 0.0001)
        let ball = Runner.builtIn(id: "hamster-ball")
        #expect(ball.pointSize == .init(width: 24, height: 18))
        #expect(abs(ball.cycleDuration - 2) < 0.0001)
        let snack = Runner.builtIn(id: "hamster-snack")
        #expect(snack.pointSize == .init(width: 22, height: 18))
        #expect(abs(snack.cycleDuration - 1.5) < 0.0001)
        #expect(Runner.builtIns.allSatisfy { !$0.isPixelArt && $0.isTemplate })
    }

    @Test func unknownOrRemovedRunnerFallsBackToHamster() {
        // 지운 러너(예전 통통·도트 고양이)나 없는 id 는 기본 러너인 깡총 햄스터로
        #expect(Runner.builtIn(id: "pixel-cat").id == "hamster")
        #expect(Runner.builtIn(id: "chubby-cat").id == "hamster")
        #expect(Runner.builtIn(id: "unknown").id == "hamster")
    }
}
