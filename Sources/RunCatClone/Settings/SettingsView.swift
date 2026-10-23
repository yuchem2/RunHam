import AppKit
import SwiftUI

/// 설정 탭 공통 폭. 탭마다 높이만 달라지고 폭은 같게 유지한다.
enum SettingsLayout {
    static let width: CGFloat = 460
}

// MARK: - General

struct GeneralSettingsView: View {
    @Bindable var settings: AppSettings
    var launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })) {
                    SettingLabel("Launch at login", symbol: "power", detail: "Start running in the menu bar when you log in.")
                }
                if let message = launchAtLogin.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section {
                LabeledContent {
                    Picker("Update Interval", selection: $settings.updateInterval) {
                        ForEach(AppSettings.updateIntervals, id: \.self) { interval in
                            Text("\(Int(interval))s").tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingLabel("Update interval", symbol: "timer", detail: "How often system metrics are sampled.")
                }
            }
            Section {
                AboutRow()
            }
        }
        .formStyle(.grouped)
        .frame(width: SettingsLayout.width)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { launchAtLogin.refresh() }
    }
}

private struct AboutRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(decorative: Runner.builtIn(id: "cat").frames[0], scale: 1)
                .resizable()
                .interpolation(.none)
                .renderingMode(.template)
                .foregroundStyle(.primary)
                .frame(width: 56, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("RunCat Clone").font(.headline)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Inspired by RunCat Neo by Takuto Nakamura (Apache License 2.0).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Runner

struct RunnerSettingsView: View {
    @Bindable var settings: AppSettings
    var metrics: SystemMetrics

    private var liveSpeed: Double {
        Double(RunnerSpeed.speed(cpuPercent: metrics.cpu.percent, decreasesUnderLoad: settings.speedDecreasesUnderLoad))
    }

    private var stageSpeed: Double {
        settings.previewFollowsCPU ? liveSpeed : settings.previewSpeed
    }

    var body: some View {
        Form {
            Section {
                RunnerStage(
                    runner: Runner.builtIn(id: settings.runnerID),
                    speed: stageSpeed,
                    flipped: settings.isFlippedHorizontally
                )
                .frame(height: 108)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                Picker("Preview", selection: $settings.previewFollowsCPU) {
                    Text("Live CPU").tag(true)
                    Text("Manual").tag(false)
                }
                .pickerStyle(.segmented)

                LabeledContent {
                    HStack(spacing: 8) {
                        Image(systemName: "tortoise.fill").foregroundStyle(.secondary)
                        Slider(
                            value: settings.previewFollowsCPU
                                ? .constant(liveSpeed)
                                : $settings.previewSpeed,
                            in: Double(RunnerSpeed.minimum)...Double(RunnerSpeed.maximum)
                        )
                        .disabled(settings.previewFollowsCPU)
                        Image(systemName: "hare.fill").foregroundStyle(.secondary)
                        Text(String(format: "×%.1f", stageSpeed))
                            .font(.callout.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                    }
                    .frame(width: 260)
                } label: {
                    Text("Speed")
                }
            }

            Section {
                Picker(selection: $settings.runnerID) {
                    ForEach(Runner.builtIns, id: \.id) { runner in
                        Text(runner.name).tag(runner.id)
                    }
                } label: {
                    SettingLabel("Runner", symbol: "cat")
                }
                Toggle(isOn: $settings.isFlippedHorizontally) {
                    SettingLabel("Flip horizontally", symbol: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle(isOn: $settings.speedDecreasesUnderLoad) {
                    SettingLabel("Slow down under load", symbol: "gauge.with.dots.needle.bottom.50percent", detail: "Runs slower as your Mac gets busier, instead of faster.")
                }
                Toggle(isOn: $settings.showsCPUUsage) {
                    SettingLabel("Show CPU usage in menu bar", symbol: "percent", detail: "Displays the current CPU percentage next to the runner.")
                }
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .frame(width: SettingsLayout.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 미리보기 무대. 메뉴바와 같은 규칙(속도 1 = 초당 2프레임)으로 프레임을 넘기고, 바닥 도트를 속도에 맞춰 흘려 보낸다.
private struct RunnerStage: View {
    static let zoom: CGFloat = 3
    static let groundSpacing: CGFloat = 12

    var runner: Runner
    var speed: Double
    var flipped: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let index = Int(time * 2 * speed) % max(runner.frames.count, 1)
            let size = runner.pointSize
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary.opacity(0.5))
                ground(offset: CGFloat((time * speed * 18).truncatingRemainder(dividingBy: Double(Self.groundSpacing))))
                Image(decorative: runner.frames[index], scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .renderingMode(.template)
                    .foregroundStyle(.primary)
                    .frame(width: size.width * Self.zoom, height: size.height * Self.zoom)
                    .scaleEffect(x: flipped ? -1 : 1)
                    .padding(.bottom, 14)
            }
        }
    }

    /// 픽셀 느낌의 점선 바닥. 러너 방향의 반대로 흐른다.
    private func ground(offset: CGFloat) -> some View {
        GeometryReader { proxy in
            let count = Int(proxy.size.width / Self.groundSpacing) + 2
            let direction: CGFloat = flipped ? 1 : -1
            HStack(spacing: Self.groundSpacing - 3) {
                ForEach(0..<count, id: \.self) { _ in
                    Rectangle().frame(width: 3, height: 3)
                }
            }
            .foregroundStyle(.tertiary)
            .offset(x: direction * offset - Self.groundSpacing, y: proxy.size.height - 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Metrics

struct MetricsSettingsView: View {
    @Bindable var settings: AppSettings
    var customMetrics: CustomMetricsStore

    var body: some View {
        Form {
            Section {
                Toggle(isOn: .constant(true)) {
                    SettingLabel("CPU", symbol: "cpu", detail: "Usage graph and user / system / idle split. Always shown.")
                }
                .disabled(true)
                Toggle(isOn: $settings.showsMemory) {
                    SettingLabel("Memory", symbol: "memorychip", detail: "App, wired and compressed memory.")
                }
                Toggle(isOn: $settings.showsStorage) {
                    SettingLabel("Storage", symbol: "internaldrive", detail: "Available space on the startup disk.")
                }
                Toggle(isOn: $settings.showsBattery) {
                    SettingLabel("Battery", symbol: "battery.75percent", detail: "Charge, cycle count and health. Hidden on Macs without a battery.")
                }
                Toggle(isOn: $settings.showsNetwork) {
                    SettingLabel("Network", symbol: "network", detail: "Connection type and current upload / download speed.")
                }
            } header: {
                Text("Dashboard Cards")
            }

            MetricsBarSection(settings: settings, customMetrics: customMetrics)

            CustomMetricsSection(store: customMetrics)
        }
        .formStyle(.grouped)
        .frame(width: SettingsLayout.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 메뉴바 상시 표시 설정. 메트릭스 바 아이콘을 눌러도 같은 항목을 켜고 끌 수 있다.
private struct MetricsBarSection: View {
    @Bindable var settings: AppSettings
    var customMetrics: CustomMetricsStore

    var body: some View {
        Section {
            Toggle(isOn: $settings.showsMetricsBar) {
                SettingLabel("Show Metrics Bar", symbol: "menubar.rectangle", detail: "Keeps selected values visible in the menu bar.")
            }
            if settings.showsMetricsBar {
                ForEach(MetricsBarConfiguration.SystemMetric.allCases, id: \.self) { metric in
                    Toggle(isOn: Binding(
                        get: { settings.metricsBar.shows(metric) },
                        set: { if $0 != settings.metricsBar.shows(metric) { settings.metricsBar.toggle(metric) } }
                    )) {
                        SettingLabel(metric.title, symbol: metric.symbol)
                    }
                }
                ForEach(customMetrics.sources) { source in
                    Toggle(isOn: Binding(
                        get: { settings.metricsBar.visibleCustomMetricsSourceIDs.contains(source.id) },
                        set: { _ in settings.metricsBar.toggleCustomMetrics(source.id) }
                    )) {
                        SettingLabel(
                            customMetrics.snapshots[source.id]?.title ?? source.fileName,
                            symbol: customMetrics.snapshots[source.id]?.resolvedSymbol ?? CustomMetricsDocument.defaultSymbol,
                            detail: "Shows its metricsBarValue."
                        )
                    }
                }
            }
        } header: {
            Text("Metrics Bar")
        } footer: {
            Text("On a MacBook with a notch, a long Metrics Bar may be hidden behind the notch or push other menu bar items out of view.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// 등록한 JSON 파일 목록. 추가할 때 스키마를 검사하고, 지울 때는 카드만 지운다고 확인받는다.
private struct CustomMetricsSection: View {
    static let schemaURL = URL(string: "https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md")!

    var store: CustomMetricsStore

    var body: some View {
        Section {
            ForEach(store.sources) { source in
                HStack(spacing: 8) {
                    Image(systemName: store.failedIDs.contains(source.id) ? "exclamationmark.triangle.fill" : "doc.text")
                        .foregroundStyle(store.failedIDs.contains(source.id) ? AnyShapeStyle(.red) : AnyShapeStyle(.tint))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.snapshots[source.id]?.title ?? source.fileName)
                        Text(source.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button {
                        confirmRemoval(of: source)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
            }
            HStack {
                Button("Add Custom Metrics Source…", action: addSource)
                Spacer()
                Link("View JSON schema", destination: Self.schemaURL)
                    .font(.caption)
            }
        } header: {
            Text("Custom Metrics")
        } footer: {
            Text("The registered JSON content is shown as cards on the dashboard and reloads whenever the file changes. Updating the content is up to you (for example, a script or cron job). Compatible with RunCat Neo's schema.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addSource() {
        let panel = NSOpenPanel()
        panel.message = "Choose a JSON file."
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.add(url)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Failed importing custom metrics source."
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func confirmRemoval(of source: CustomMetricsStore.Source) {
        let alert = NSAlert()
        alert.messageText = "Remove Custom Metrics?"
        alert.informativeText = "Its card will disappear from the dashboard. The underlying JSON file on disk is not deleted."
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            store.remove(source.id)
        }
    }
}

// MARK: - 공통

/// 아이콘 + 제목 + (선택) 한 줄 설명.
private struct SettingLabel: View {
    var title: String
    var symbol: String
    var detail: String?

    init(_ title: String, symbol: String, detail: String? = nil) {
        self.title = title
        self.symbol = symbol
        self.detail = detail
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 20)
        }
    }
}
