import AppKit

/// 메뉴바에 수치를 상시 표시하는 두 번째 상태 아이템. 누르면 표시 항목을 켜고 끄는 메뉴가 열린다.
@MainActor
final class MetricsBarController: NSObject, NSMenuDelegate {
    private let settings: AppSettings
    private let metrics: SystemMetrics
    private let customMetrics: CustomMetricsStore
    private var statusItem: NSStatusItem?
    private var renderedItems: [MetricsBarItem]?
    private let menu = NSMenu()

    var onOpenSettings: (() -> Void)?

    init(settings: AppSettings, metrics: SystemMetrics, customMetrics: CustomMetricsStore) {
        self.settings = settings
        self.metrics = metrics
        self.customMetrics = customMetrics
        super.init()
        menu.delegate = self
    }

    /// 설정이 바뀌거나 측정값이 갱신될 때마다 부른다. 그릴 내용이 같으면 이미지를 다시 만들지 않는다.
    func update() {
        guard settings.showsMetricsBar else {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
                renderedItems = nil
            }
            return
        }
        let item = statusItem ?? makeStatusItem()
        let items = Self.items(configuration: settings.metricsBar, metrics: metrics, customMetrics: customMetrics)
        guard items != renderedItems else { return }
        renderedItems = items
        item.button?.image = MetricsBarRenderer.image(for: items)
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "MetricsBar"
        item.button?.imagePosition = .imageOnly
        item.menu = menu
        statusItem = item
        return item
    }

    // MARK: - 항목 구성

    static func items(
        configuration: MetricsBarConfiguration,
        metrics: SystemMetrics,
        customMetrics: CustomMetricsStore
    ) -> [MetricsBarItem] {
        let percentReference = "100.0%"
        var items: [MetricsBarItem] = []
        if configuration.showsCPU {
            items.append(.init(symbol: "cpu", content: .value(Format.percent(metrics.cpu.percent), reference: percentReference)))
        }
        if configuration.showsMemory, let memory = metrics.memory {
            items.append(.init(symbol: "memorychip", content: .value(Format.percent(memory.ratio * 100), reference: percentReference)))
        }
        if configuration.showsStorage, let storage = metrics.storage {
            items.append(.init(symbol: "internaldrive", content: .value(Format.percent(storage.ratio * 100), reference: percentReference)))
        }
        if configuration.showsBattery, let battery = metrics.battery {
            items.append(.init(symbol: Format.batterySymbol(battery), content: .value("\(battery.level)%", reference: "100%")))
        }
        if configuration.showsNetwork {
            if metrics.isNetworkConnected {
                items.append(.init(symbol: "network", content: .dual(
                    top: "↑" + Format.shortRate(metrics.throughput.sent),
                    bottom: "↓" + Format.shortRate(metrics.throughput.received)
                )))
            } else {
                items.append(.init(symbol: "network.slash", content: .iconOnly))
            }
        }
        for source in customMetrics.enabledSources where configuration.visibleCustomMetricsSourceIDs.contains(source.id) {
            let document = customMetrics.snapshots[source.id]
            let failed = customMetrics.failedIDs.contains(source.id)
            // 값이 없거나 읽기에 실패하면 `---` 를 보여 준다.
            let value = failed ? nil : document?.metricsBarValue
            items.append(.init(
                symbol: document?.resolvedSymbol ?? CustomMetricsDocument.defaultSymbol,
                content: .freeform(value ?? "---")
            ))
        }
        return items
    }

    // MARK: - 메뉴

    func menuNeedsUpdate(_ menu: NSMenu) {
        let configuration = settings.metricsBar
        menu.removeAllItems()

        let header = NSMenuItem(title: L("metricsBar.title"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for kind in MetricsBarConfiguration.SystemMetric.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(toggleSystemMetric(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = kind.rawValue
            item.state = configuration.shows(kind) ? .on : .off
            item.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: nil)
            menu.addItem(item)
        }

        if !customMetrics.sources.isEmpty {
            menu.addItem(.separator())
            let customHeader = NSMenuItem(title: L("custom.title"), action: nil, keyEquivalent: "")
            customHeader.isEnabled = false
            menu.addItem(customHeader)
            for source in customMetrics.sources {
                let document = customMetrics.snapshots[source.id]
                let item = NSMenuItem(title: document?.title ?? source.fileName, action: #selector(toggleCustomMetric(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = source.id
                item.state = configuration.visibleCustomMetricsSourceIDs.contains(source.id) ? .on : .off
                item.image = NSImage(systemSymbolName: document?.resolvedSymbol ?? CustomMetricsDocument.defaultSymbol, accessibilityDescription: nil)
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: L("menu.settings"), action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let hideItem = NSMenuItem(title: L("metricsBar.hide"), action: #selector(hide), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)
    }

    @objc private func toggleSystemMetric(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let kind = MetricsBarConfiguration.SystemMetric(rawValue: raw) else { return }
        settings.metricsBar.toggle(kind)
    }

    @objc private func toggleCustomMetric(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        settings.metricsBar.toggleCustomMetrics(id)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func hide() {
        settings.showsMetricsBar = false
    }
}
