/// CPU 사용률 → 애니메이션 속도 배율. CPU 5% 마다 1배씩, 1~20배.
enum RunnerSpeed {
    static let minimum: Float = 1
    static let maximum: Float = 20

    static func speed(cpuPercent: Double, decreasesUnderLoad: Bool) -> Float {
        let speed = max(minimum, min(maximum, Float(cpuPercent) / 5))
        return decreasesUnderLoad ? (maximum + 1 - speed) * 0.5 : speed
    }
}
