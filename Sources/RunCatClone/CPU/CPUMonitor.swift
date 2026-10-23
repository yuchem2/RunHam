import Foundation

/// 주기적으로 CPU 사용률을 샘플링해 링버퍼 평균(퍼센트)을 전달한다.
@MainActor
final class CPUMonitor {
    private var previous: CPUTicks?
    private var buffer: RingBuffer
    private var timer: Timer?
    private let readTicks: () -> CPUTicks?

    var onUpdate: ((Double) -> Void)?
    private(set) var latestPercent: Double = 0

    init(bufferSize: Int = 5, readTicks: @escaping () -> CPUTicks? = CPUTicks.current) {
        self.buffer = RingBuffer(capacity: bufferSize)
        self.readTicks = readTicks
    }

    func start(interval: TimeInterval) {
        stop()
        previous = readTicks()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        timer.tolerance = interval * 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func sample() {
        guard let current = readTicks() else { return }
        defer { previous = current }
        guard let previous else { return }
        buffer.append(CPUUsage.ratio(from: previous, to: current))
        latestPercent = CPUUsage.percent(fromRatio: buffer.average)
        onUpdate?(latestPercent)
    }
}
