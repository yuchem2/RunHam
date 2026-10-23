import AppKit
import SwiftUI

/// 설정 탭 공통 폭. 탭마다 높이만 달라지고 폭은 같게 유지한다.
enum SettingsLayout {
    static let width: CGFloat = 460
    /// 라이트 모드에선 흰색, 다크 모드에선 어두운 텍스트 배경색
    static let background = Color(nsColor: .textBackgroundColor)
}

extension View {
    /// 기본 grouped Form 은 회색 바탕에 회색 상자라 설명 글씨가 흐리게 보여서 흰 바탕으로 바꾼다.
    func settingsFormStyle() -> some View {
        formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(SettingsLayout.background)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @Bindable var settings: AppSettings
    var launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })) {
                    SettingLabel(L("settings.launchAtLogin"), symbol: "power", detail: L("settings.launchAtLogin.detail"))
                }
                if let message = launchAtLogin.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section {
                LabeledContent {
                    Picker(L("settings.language"), selection: $settings.language) {
                        ForEach(AppLanguage.available) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingLabel(L("settings.language"), symbol: "globe", detail: L("settings.language.detail"))
                }
                LabeledContent {
                    Picker(L("settings.updateInterval"), selection: $settings.updateInterval) {
                        ForEach(AppSettings.updateIntervals, id: \.self) { interval in
                            Text(L("settings.seconds", Int(interval))).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingLabel(L("settings.updateInterval"), symbol: "timer", detail: L("settings.updateInterval.detail"))
                }
            }
            Section {
                AboutRow()
            }
        }
        .settingsFormStyle()
        .frame(width: SettingsLayout.width)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { launchAtLogin.refresh() }
    }
}

private struct AboutRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // 대표 캐릭터: 쳇바퀴 햄스터
            let mascot = Runner.builtIns[0]
            Image(decorative: mascot.previewFrames[0], scale: 1)
                .resizable()
                .interpolation(mascot.isPixelArt ? .none : .high)
                .renderingMode(.template)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(L("app.name")).font(.headline)
                Text(L("about.version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(L("about.credit"))
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
    var customRunners: CustomRunnerStore

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
                    runner: Runner.resolve(id: settings.runnerID, custom: customRunners),
                    speed: stageSpeed,
                    flipped: settings.isFlippedHorizontally
                )
                .frame(height: 108)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                Picker(L("settings.preview"), selection: $settings.previewFollowsCPU) {
                    Text(L("settings.preview.live")).tag(true)
                    Text(L("settings.preview.manual")).tag(false)
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
                    Text(L("settings.speed"))
                }
            }

            Section {
                Picker(selection: $settings.runnerID) {
                    ForEach(Runner.builtIns, id: \.id) { runner in
                        Text(runner.name).tag(runner.id)
                    }
                    if !customRunners.runners.isEmpty {
                        Divider()
                        ForEach(customRunners.runners, id: \.id) { runner in
                            Text(runner.name).tag(runner.id)
                        }
                    }
                } label: {
                    SettingLabel(L("settings.runner"), symbol: "cat")
                }
                Toggle(isOn: $settings.isFlippedHorizontally) {
                    SettingLabel(L("settings.flip"), symbol: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
            } header: {
                Text(L("settings.section.appearance"))
            }

            CustomRunnersSection(store: customRunners, settings: settings)

            Section {
                Toggle(isOn: $settings.speedDecreasesUnderLoad) {
                    SettingLabel(L("settings.slowDown"), symbol: "gauge.with.dots.needle.bottom.50percent", detail: L("settings.slowDown.detail"))
                }
                Toggle(isOn: $settings.showsCPUUsage) {
                    SettingLabel(L("settings.showCPU"), symbol: "percent", detail: L("settings.showCPU.detail"))
                }
            } header: {
                Text(L("settings.section.behavior"))
            }
        }
        .settingsFormStyle()
        .frame(width: SettingsLayout.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 미리보기 무대: 둥근 배경 위에 Core Animation 으로 도는 러너(RunnerStageView)
private struct RunnerStage: View {
    var runner: Runner
    var speed: Double
    var flipped: Bool

    var body: some View {
        RunnerStageView(runner: runner, speed: speed, flipped: flipped)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// RunCat Neo 처럼 PNG 프레임 폴더로 추가하는 커스텀 러너 목록
private struct CustomRunnersSection: View {
    static let galleryURL = URL(string: "https://runcat-dev.github.io/RunnerGallery/")!

    var store: CustomRunnerStore
    var settings: AppSettings

    var body: some View {
        Section {
            ForEach(store.runners, id: \.id) { runner in
                HStack(spacing: 10) {
                    RunnerThumbnail(runner: runner)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(runner.name)
                        Text(L("customRunner.frames", runner.frames.count, runner.frames[0].width, runner.frames[0].height))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(L("customRunner.keepColors"), isOn: Binding(
                        get: { !runner.isTemplate },
                        set: { store.setTemplate(!$0, id: runner.id) }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    Button {
                        confirmRemoval(of: runner)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L("common.remove"))
                }
            }
            HStack {
                Button(L("customRunner.add"), action: addRunner)
                Spacer()
                Link(L("customRunner.gallery"), destination: Self.galleryURL)
                    .font(.caption)
            }
        } header: {
            Text(L("settings.section.customRunners"))
        } footer: {
            Text(L("customRunner.requirements"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addRunner() {
        let panel = NSOpenPanel()
        panel.message = L("customRunner.choose")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }

        // 이름과 색상 처리 방식을 한 번에 묻는다
        let alert = NSAlert()
        alert.messageText = L("customRunner.import.title")
        alert.informativeText = L("customRunner.import.message")
        let nameField = NSTextField(string: CustomRunnerImporter.suggestedName(for: folder))
        nameField.frame = NSRect(x: 0, y: 24, width: 240, height: 24)
        let keepColors = NSButton(checkboxWithTitle: L("customRunner.keepColors"), target: nil, action: nil)
        keepColors.frame = NSRect(x: 0, y: 0, width: 240, height: 18)
        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 48))
        accessory.addSubview(nameField)
        accessory.addSubview(keepColors)
        alert.accessoryView = accessory
        alert.addButton(withTitle: L("common.add"))
        alert.addButton(withTitle: L("common.cancel"))
        alert.window.initialFirstResponder = nameField
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        do {
            let runner = try store.add(folder: folder, name: nameField.stringValue, isTemplate: keepColors.state != .on)
            settings.runnerID = runner.id
        } catch {
            let failure = NSAlert()
            failure.alertStyle = .warning
            failure.messageText = L("customRunner.importFailed")
            failure.informativeText = error.localizedDescription
            failure.runModal()
        }
    }

    private func confirmRemoval(of runner: Runner) {
        let alert = NSAlert()
        alert.messageText = L("customRunner.remove.title")
        alert.informativeText = L("customRunner.remove.message")
        alert.addButton(withTitle: L("common.remove"))
        alert.addButton(withTitle: L("common.cancel"))
        if alert.runModal() == .alertFirstButtonReturn {
            store.remove(id: runner.id)
        }
    }
}

/// 목록에 보여 줄 첫 프레임. 템플릿 러너는 글자색으로 칠한다.
private struct RunnerThumbnail: View {
    var runner: Runner

    var body: some View {
        Image(decorative: runner.frames[0], scale: Runner.scale)
            .renderingMode(runner.isTemplate ? .template : .original)
            .foregroundStyle(.primary)
            .frame(width: 50, height: 18)
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
                    SettingLabel(L("metric.cpu"), symbol: "cpu", detail: L("settings.card.cpu.detail"))
                }
                .disabled(true)
                Toggle(isOn: $settings.showsMemory) {
                    SettingLabel(L("metric.memory"), symbol: "memorychip", detail: L("settings.card.memory.detail"))
                }
                Toggle(isOn: $settings.showsStorage) {
                    SettingLabel(L("metric.storage"), symbol: "internaldrive", detail: L("settings.card.storage.detail"))
                }
                Toggle(isOn: $settings.showsBattery) {
                    SettingLabel(L("metric.battery"), symbol: "battery.75percent", detail: L("settings.card.battery.detail"))
                }
                Toggle(isOn: $settings.showsNetwork) {
                    SettingLabel(L("metric.network"), symbol: "network", detail: L("settings.card.network.detail"))
                }
            } header: {
                Text(L("settings.section.dashboardCards"))
            }

            MetricsBarSection(settings: settings, customMetrics: customMetrics)

            CustomMetricsSection(store: customMetrics)
        }
        .settingsFormStyle()
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
            Toggle(isOn: Binding(
                get: { settings.showsMetricsBar },
                set: { newValue in
                    if newValue {
                        MetricsBarNotice.confirmEnabling(settings: settings)
                    } else {
                        settings.showsMetricsBar = false
                    }
                }
            )) {
                SettingLabel(L("settings.showMetricsBar"), symbol: "menubar.rectangle", detail: L("settings.showMetricsBar.detail"))
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
                            detail: L("settings.metricsBar.customDetail")
                        )
                    }
                }
            }
        } header: {
            Text(L("metricsBar.title"))
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
                    .help(L("common.remove"))
                }
            }
            HStack {
                Button(L("custom.add"), action: addSource)
                Spacer()
                Link(L("custom.schema"), destination: Self.schemaURL)
                    .font(.caption)
            }
        } header: {
            Text(L("custom.title"))
        } footer: {
            Text(L("custom.footer"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addSource() {
        let panel = NSOpenPanel()
        panel.message = L("custom.choose")
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.add(url)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L("custom.importFailed")
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func confirmRemoval(of source: CustomMetricsStore.Source) {
        let alert = NSAlert()
        alert.messageText = L("custom.remove.title")
        alert.informativeText = L("custom.remove.message")
        alert.addButton(withTitle: L("common.remove"))
        alert.addButton(withTitle: L("common.cancel"))
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
