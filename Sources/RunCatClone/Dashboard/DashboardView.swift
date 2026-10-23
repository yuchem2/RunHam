import AppKit
import SwiftUI

/// 상태바 메뉴 맨 위에 넣는 시스템 메트릭 카드 묶음.
struct DashboardView: View {
    var metrics: SystemMetrics
    var settings: AppSettings
    var customMetrics: CustomMetricsStore

    static let width: CGFloat = 300

    var body: some View {
        VStack(spacing: 8) {
            cpuCard
            if settings.showsMemory, let memory = metrics.memory {
                memoryCard(memory)
            }
            if settings.showsStorage, let storage = metrics.storage {
                storageCard(storage)
            }
            if settings.showsBattery, let battery = metrics.battery {
                batteryCard(battery)
            }
            if settings.showsNetwork {
                networkCard
            }
            ForEach(customMetrics.sources) { source in
                CustomMetricsCard(
                    source: source,
                    document: customMetrics.snapshots[source.id],
                    failed: customMetrics.failedIDs.contains(source.id)
                )
            }
            if let updated = metrics.lastUpdated {
                Text("Last updated: \(updated.formatted(Date.FormatStyle(date: .omitted, time: .standard).locale(Format.locale)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: Self.width)
    }

    private var cpuCard: some View {
        MetricCard(symbol: "cpu", title: "CPU", value: Format.percent(metrics.cpu.percent)) {
            LineGraph(values: metrics.cpuHistory, capacity: SystemMetrics.historyLength, maximum: 100)
                .frame(height: 36)
            Text("User \(Format.percent(metrics.cpu.user)) · System \(Format.percent(metrics.cpu.system)) · Idle \(Format.percent(metrics.cpu.idle))")
        }
    }

    private func memoryCard(_ memory: MemoryUsage) -> some View {
        MetricCard(symbol: "memorychip", title: "Memory", value: Format.percent(memory.ratio * 100)) {
            UsageBar(ratio: memory.ratio)
            Text("\(Format.memory(memory.used)) used of \(Format.memory(memory.total))")
            HStack {
                Text("App \(Format.memory(memory.app))")
                Spacer()
                Text("Wired \(Format.memory(memory.wired))")
                Spacer()
                Text("Compressed \(Format.memory(memory.compressed))")
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private func storageCard(_ storage: StorageUsage) -> some View {
        MetricCard(symbol: "internaldrive", title: "Storage", value: Format.percent(storage.ratio * 100)) {
            UsageBar(ratio: storage.ratio)
            Text("\(Format.file(storage.available)) available of \(Format.file(storage.total))")
        }
    }

    private func batteryCard(_ battery: BatteryStatus) -> some View {
        MetricCard(symbol: Format.batterySymbol(battery), title: "Battery", value: "\(battery.level)%") {
            UsageBar(ratio: Double(battery.level) / 100, inverted: true)
            Text(Format.batteryDetail(battery))
        }
    }

    private var networkCard: some View {
        MetricCard(
            symbol: metrics.isNetworkConnected ? "network" : "network.slash",
            title: "Network",
            value: metrics.isNetworkConnected ? (metrics.networkInterface ?? "Connected") : "Offline"
        ) {
            HStack {
                Label(Format.rate(metrics.throughput.received), systemImage: "arrow.down")
                Spacer()
                Label(Format.rate(metrics.throughput.sent), systemImage: "arrow.up")
            }
            if let ipv4 = metrics.addresses.ipv4 {
                AddressRow(label: "IPv4", address: ipv4, interface: metrics.networkBSDName)
            }
            if let ipv6 = metrics.addresses.ipv6 {
                AddressRow(label: "IPv6", address: ipv6, interface: nil)
            }
        }
    }
}

private struct MetricCard<Content: View>: View {
    var symbol: String
    var title: String
    var value: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.headline.monospacedDigit())
            }
            VStack(alignment: .leading, spacing: 3) {
                content
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Custom Metrics JSON 한 개를 카드로 그린다. 행은 `title: formattedValue`, normalizedValue 가 있으면 강조색 막대.
private struct CustomMetricsCard: View {
    var source: CustomMetricsStore.Source
    var document: CustomMetricsDocument?
    var failed: Bool

    var body: some View {
        MetricCard(
            symbol: document?.resolvedSymbol ?? CustomMetricsDocument.defaultSymbol,
            title: document?.title ?? source.fileName,
            value: ""
        ) {
            ForEach(Array((document?.metrics ?? []).enumerated()), id: \.offset) { _, metric in
                Text("\(metric.title): \(metric.formattedValue)")
                    .lineLimit(1)
                if let ratio = metric.normalizedValue {
                    UsageBar(ratio: ratio, tint: .accentColor)
                }
            }
            if failed || document == nil {
                Label("Error Detected", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if let updated = document?.lastUpdatedDate {
                Text("Updated \(updated.formatted(.relative(presentation: .named).locale(Format.locale)))")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// IP 주소 한 줄. 누르면 주소를 클립보드에 복사한다.
private struct AddressRow: View {
    var label: String
    var address: String
    var interface: String?

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(address, forType: .string)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .frame(width: 30, alignment: .leading)
                Text(address)
                    .foregroundStyle(.primary)
                    .textSelection(.disabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let interface {
                    Text("(\(interface))")
                }
                Spacer(minLength: 4)
                Image(systemName: "doc.on.doc")
                    .imageScale(.small)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Copy \(address)")
    }
}

/// 사용률 막대. 높을수록 경고색(배터리는 inverted 로 낮을수록 경고색).
private struct UsageBar: View {
    var ratio: Double
    var inverted = false
    /// 지정하면 사용률과 관계없이 이 색으로 칠한다.
    var tint: Color?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: 6)
    }

    private var color: Color {
        if let tint { return tint }
        let level = inverted ? 1 - ratio : ratio
        switch level {
        case ..<0.6: return .green
        case ..<0.85: return .orange
        default: return .red
        }
    }
}

/// 오른쪽 끝이 최신값인 꺾은선 그래프. 아직 채워지지 않은 왼쪽은 비워 둔다.
private struct LineGraph: View {
    var values: [Double]
    var capacity: Int
    var maximum: Double

    var body: some View {
        GeometryReader { proxy in
            let points = points(in: proxy.size)
            ZStack {
                if let first = points.first, let last = points.last {
                    Path { path in
                        path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                        points.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [.accentColor.opacity(0.35), .accentColor.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                    Path { path in path.addLines(points) }
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                }
            }
        }
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard capacity > 1 else { return [] }
        let step = size.width / CGFloat(capacity - 1)
        let offset = capacity - values.count
        return values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(offset + index) * step,
                y: size.height * (1 - CGFloat(min(max(value / maximum, 0), 1)))
            )
        }
    }
}

enum Format {
    /// UI 문자열이 영어뿐이라 날짜도 앱 현지화(영어)에 맞춰 섞이지 않게 한다.
    static let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    static func memory(_ bytes: UInt64) -> String {
        // 소수 둘째 자리까지 나오면 카드 폭을 넘으므로 GB 이상은 한 자리로 줄인다.
        let gigabytes = Double(bytes) / 1_073_741_824
        return gigabytes >= 1 ? String(format: "%.1f GB", gigabytes) : ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    static func file(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesPerSecond), countStyle: .file) + "/s"
    }

    /// 메트릭스 바용 짧은 속도 표기(예: 1.2MB/s). 10진 단위.
    static func shortRate(_ bytesPerSecond: Double) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var value = max(bytesPerSecond, 0)
        var index = 0
        while value >= 1000, index < units.count - 1 {
            value /= 1000
            index += 1
        }
        return index == 0 ? String(format: "%.0f%@/s", value, units[index]) : String(format: "%.1f%@/s", value, units[index])
    }

    static func batterySymbol(_ battery: BatteryStatus) -> String {
        if battery.isCharging { return "battery.100percent.bolt" }
        switch battery.level {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    static func batteryDetail(_ battery: BatteryStatus) -> String {
        var parts = [battery.isCharging ? "Charging" : (battery.isPluggedIn ? "Plugged in" : "On battery")]
        if let cycles = battery.cycleCount { parts.append("\(cycles) cycles") }
        if let health = battery.health { parts.append("Health \(Int((health * 100).rounded()))%") }
        return parts.joined(separator: " · ")
    }
}
