import Darwin
import Foundation

/// 루프백을 제외한 활성 인터페이스들의 누적 송수신 바이트.
struct NetworkCounters: Equatable, Sendable {
    var received: UInt64
    var sent: UInt64

    /// 원본은 `getifaddrs` 를 쓰지만 그 `if_data` 카운터는 32비트라 4GB 마다 되감긴다.
    /// 여기선 `NET_RT_IFLIST2` 의 64비트 카운터(`if_data64`)를 읽는다.
    static func current() -> NetworkCounters? {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else { return nil }

        var counters = NetworkCounters(received: 0, sent: 0)
        buffer.withUnsafeBytes { raw in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                guard header.ifm_msglen > 0 else { break }
                if Int32(header.ifm_type) == RTM_IFINFO2 {
                    let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                    let flags = message.ifm_flags
                    if flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 {
                        counters.received += message.ifm_data.ifi_ibytes
                        counters.sent += message.ifm_data.ifi_obytes
                    }
                }
                offset += Int(header.ifm_msglen)
            }
        }
        return counters
    }
}

/// 초당 송수신 바이트.
struct NetworkThroughput: Equatable, Sendable {
    var received: Double
    var sent: Double

    static let zero = NetworkThroughput(received: 0, sent: 0)

    init(received: Double, sent: Double) {
        self.received = received
        self.sent = sent
    }

    /// 인터페이스가 내려가 카운터 합이 줄어든 구간은 0 으로 본다.
    init(from old: NetworkCounters, to new: NetworkCounters, interval: TimeInterval) {
        guard interval > 0 else {
            self = .zero
            return
        }
        received = new.received >= old.received ? Double(new.received - old.received) / interval : 0
        sent = new.sent >= old.sent ? Double(new.sent - old.sent) / interval : 0
    }
}
