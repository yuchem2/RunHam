import Foundation
import Testing
@testable import RunHam

@MainActor
struct MetricsBarTests {
    private func makeStore() -> CustomMetricsStore {
        CustomMetricsStore(defaults: UserDefaults(suiteName: "RunHamTests.\(UUID().uuidString)")!)
    }

    private func makeMetrics() -> SystemMetrics {
        let metrics = SystemMetrics()
        metrics.appendCPU(CPUSnapshot(percent: 12.3, user: 8, system: 4.3, idle: 87.7))
        metrics.memory = MemoryUsage(total: 100, app: 40, wired: 10, compressed: 0)
        metrics.isNetworkConnected = true
        metrics.throughput = NetworkThroughput(received: 1_234_567, sent: 980)
        return metrics
    }

    @Test func defaultShowsOnlyCPU() {
        let items = MetricsBarController.items(configuration: .default, metrics: makeMetrics(), customMetrics: makeStore())
        #expect(items == [MetricsBarItem(symbol: "cpu", content: .value("12.3%", reference: "100.0%"))])
    }

    @Test func skipsUnavailableMetricsAndShowsNetworkRates() {
        let configuration = MetricsBarConfiguration(showsCPU: false, showsMemory: true, showsStorage: true, showsBattery: true, showsNetwork: true)
        let items = MetricsBarController.items(configuration: configuration, metrics: makeMetrics(), customMetrics: makeStore())
        // 저장공간·배터리 값이 없으면 항목을 그리지 않는다.
        #expect(items.map(\.symbol) == ["memorychip", "network"])
        #expect(items[1].content == .dual(top: "↑980B/s", bottom: "↓1.2MB/s"))
    }

    @Test func offlineNetworkIsIconOnly() {
        let metrics = makeMetrics()
        metrics.isNetworkConnected = false
        let configuration = MetricsBarConfiguration(showsCPU: false, showsNetwork: true)
        let items = MetricsBarController.items(configuration: configuration, metrics: metrics, customMetrics: makeStore())
        #expect(items == [MetricsBarItem(symbol: "network.slash", content: .iconOnly)])
    }

    @Test func customMetricsShowBarValueOrPlaceholder() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RunHamTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let withValue = directory.appendingPathComponent("a.json")
        let withoutValue = directory.appendingPathComponent("b.json")
        try Data(#"{"title":"A","symbol":"star","metricsBarValue":"42","metrics":[],"lastUpdatedDate":"2026-06-05T04:50:40Z"}"#.utf8).write(to: withValue)
        try Data(#"{"title":"B","metrics":[],"lastUpdatedDate":"2026-06-05T04:50:40Z"}"#.utf8).write(to: withoutValue)
        let store = makeStore()
        try store.add(withValue)
        try store.add(withoutValue)

        var configuration = MetricsBarConfiguration(showsCPU: false)
        store.sources.forEach { configuration.toggleCustomMetrics($0.id) }
        let items = MetricsBarController.items(configuration: configuration, metrics: makeMetrics(), customMetrics: store)
        #expect(items == [
            MetricsBarItem(symbol: "star", content: .freeform("42")),
            MetricsBarItem(symbol: CustomMetricsDocument.defaultSymbol, content: .freeform("---")),
        ])
        store.sources.forEach { store.remove($0.id) }
    }

    @Test func configurationRoundTripsThroughSettings() {
        let defaults = UserDefaults(suiteName: "RunHamTests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)
        #expect(settings.metricsBar == .default)
        #expect(settings.showsMetricsBar == false)
        settings.metricsBar.toggle(.memory)
        settings.showsMetricsBar = true
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.metricsBar.showsMemory)
        #expect(reloaded.showsMetricsBar)
    }

    @Test func widthIsStableAcrossValues() {
        let low = [MetricsBarItem(symbol: "cpu", content: .value("1.0%", reference: "100.0%"))]
        let high = [MetricsBarItem(symbol: "cpu", content: .value("99.9%", reference: "100.0%"))]
        #expect(MetricsBarRenderer.width(of: low) == MetricsBarRenderer.width(of: high))
        #expect(MetricsBarRenderer.width(of: []) == SleepingHamsterSprite.pointSize.width)
        let long = [MetricsBarItem(symbol: "star", content: .freeform(String(repeating: "W", count: 50)))]
        #expect(MetricsBarRenderer.width(of: long) == MetricsBarRenderer.iconSize.width + MetricsBarRenderer.freeformMaxWidth)
    }

    @Test(arguments: [(0.0, "0B/s"), (999.0, "999B/s"), (1_500.0, "1.5KB/s"), (2_000_000.0, "2.0MB/s")])
    func shortRateFormatting(bytes: Double, expected: String) {
        #expect(Format.shortRate(bytes) == expected)
    }
}
