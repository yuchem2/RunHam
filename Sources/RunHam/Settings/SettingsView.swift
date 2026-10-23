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
    /// 번들 아이콘(.icns)과 같은 그림. 개발 실행(번들 밖)에서도 똑같이 보이도록 직접 그린다.
    static let appIcon = AppIconRenderer.render(pixels: 88)

    var body: some View {
        HStack(spacing: 12) {
            Image(decorative: Self.appIcon, scale: 2)
                .resizable()
                .interpolation(.high)
                .frame(width: 44, height: 44)
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
                    SettingLabel(L("settings.runner"), icon: Image(decorative: HamsterSymbol.image, scale: 1).resizable())
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

/// PNG 프레임으로 만드는 커스텀 러너 목록. 추가·편집은 시트에서 이름·색상·프레임 순서를 정한다.
private struct CustomRunnersSection: View {
    static let galleryURL = URL(string: "https://runcat-dev.github.io/RunnerGallery/")!

    var store: CustomRunnerStore
    var settings: AppSettings
    @State private var draft: CustomRunnerDraft?

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
                    Button {
                        draft = CustomRunnerDraft(editingID: runner.id, name: runner.name, isTemplate: runner.isTemplate, images: store.frames(of: runner.id))
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L("common.edit"))
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
                Button(L("customRunner.add")) { draft = CustomRunnerDraft() }
                Spacer()
                Link(L("customRunner.gallery"), destination: Self.galleryURL)
                    .font(.caption)
            }
        } header: {
            Text(L("settings.section.customRunners"))
        }
        .sheet(item: $draft) { draft in
            CustomRunnerEditorView(draft: draft, onCancel: { self.draft = nil }, onSave: { save(draft) })
        }
    }

    private func save(_ draft: CustomRunnerDraft) {
        let images = draft.frames.map(\.image)
        do {
            if let id = draft.editingID {
                try store.update(id: id, frames: images, name: draft.name, isTemplate: draft.isTemplate)
            } else {
                let runner = try store.add(frames: images, name: draft.name, isTemplate: draft.isTemplate)
                settings.runnerID = runner.id
            }
            self.draft = nil
        } catch {
            draft.errorMessage = error.localizedDescription
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
    var icon: Image
    var isSymbol: Bool
    var detail: String?

    init(_ title: String, symbol: String, detail: String? = nil) {
        self.title = title
        self.icon = Image(systemName: symbol)
        self.isSymbol = true
        self.detail = detail
    }

    /// SF Symbol 이 아닌 템플릿 이미지 아이콘(예: 외곽선 햄스터)
    init(_ title: String, icon: Image, detail: String? = nil) {
        self.title = title
        self.icon = icon
        self.isSymbol = false
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
            if isSymbol {
                icon
                    .foregroundStyle(.tint)
                    .frame(width: 20)
            } else {
                icon
                    .renderingMode(.template)
                    .interpolation(.high)
                    .scaledToFit()
                    .foregroundStyle(.tint)
                    .frame(width: 20, height: 16)
            }
        }
    }
}
