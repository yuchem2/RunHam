/// 최근 N 개의 값만 보관하는 고정 크기 버퍼.
struct RingBuffer: Sendable {
    let capacity: Int
    private var storage: [Double] = []
    private var head = 0

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    var isEmpty: Bool { storage.isEmpty }

    var average: Double {
        storage.isEmpty ? 0 : storage.reduce(0, +) / Double(storage.count)
    }

    mutating func append(_ value: Double) {
        if storage.count < capacity {
            storage.append(value)
        } else {
            storage[head] = value
            head = (head + 1) % capacity
        }
    }
}
