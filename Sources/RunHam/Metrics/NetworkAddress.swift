import Darwin

/// 한 인터페이스(en0 등)에 할당된 로컬 IP 주소. 외부 서비스에 묻지 않으므로 공인 IP 는 알 수 없다.
struct NetworkAddresses: Equatable, Sendable {
    var ipv4: String?
    /// 링크 로컬(fe80::)을 제외한 첫 IPv6 주소
    var ipv6: String?

    static func current(interface: String) -> NetworkAddresses {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return NetworkAddresses() }
        defer { freeifaddrs(head) }

        var result = NetworkAddresses()
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            guard String(cString: entry.ifa_name) == interface, let address = entry.ifa_addr else { continue }
            switch Int32(address.pointee.sa_family) {
            case AF_INET where result.ipv4 == nil:
                result.ipv4 = numericHost(address)
            case AF_INET6 where result.ipv6 == nil:
                if let host = numericHost(address), !host.lowercased().hasPrefix("fe80") {
                    result.ipv6 = host
                }
            default:
                break
            }
        }
        return result
    }

    private static func numericHost(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = getnameinfo(address, socklen_t(address.pointee.sa_len), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST)
        guard status == 0 else { return nil }
        // IPv6 스코프 표기(%en0)는 떼어 낸다.
        return String(cString: buffer).split(separator: "%").first.map(String.init)
    }
}
