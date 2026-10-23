/// 한 번의 CPU 측정 결과. 퍼센트(0...100) 단위.
struct CPUSnapshot: Equatable, Sendable {
    /// 링버퍼 평균 사용률 — 러너 속도와 메뉴바 표시에 쓴다.
    var percent: Double
    var user: Double
    var system: Double
    var idle: Double

    static let zero = CPUSnapshot(percent: 0, user: 0, system: 0, idle: 100)
}

/// 이전 tick 을 기억해 두었다가 호출될 때마다 델타로 사용률을 계산한다.
struct CPUSampler {
    private var previous: CPUTicks?
    private var buffer: RingBuffer

    init(bufferSize: Int = 5) {
        buffer = RingBuffer(capacity: bufferSize)
    }

    /// 첫 호출은 기준점만 저장하고 nil 을 돌려준다.
    mutating func sample(_ current: CPUTicks) -> CPUSnapshot? {
        defer { previous = current }
        guard let previous else { return nil }
        let breakdown = CPUUsage.breakdown(from: previous, to: current)
        buffer.append(CPUUsage.ratio(from: previous, to: current))
        return CPUSnapshot(
            percent: CPUUsage.percent(fromRatio: buffer.average),
            user: CPUUsage.percent(fromRatio: breakdown.user),
            system: CPUUsage.percent(fromRatio: breakdown.system),
            idle: CPUUsage.percent(fromRatio: breakdown.idle)
        )
    }
}
