import SwiftUI

/// 원본처럼 General / Runner / Metrics 탭으로 나눈 설정 화면.
struct SettingsView: View {
    @Bindable var settings: AppSettings
    var launchAtLogin: LaunchAtLogin

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)
                .tabItem { Label("General", systemImage: "gearshape") }
            RunnerSettingsView(settings: settings)
                .tabItem { Label("Runner", systemImage: "cat") }
            MetricsSettingsView(settings: settings)
                .tabItem { Label("Metrics", systemImage: "gauge.with.dots.needle.33percent") }
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct GeneralSettingsView: View {
    @Bindable var settings: AppSettings
    var launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            Section {
                Toggle("Launch RunCat Clone at login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                if let message = launchAtLogin.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section {
                Picker("Update Interval", selection: $settings.updateInterval) {
                    ForEach(AppSettings.updateIntervals, id: \.self) { interval in
                        Text("\(Int(interval)) s").tag(interval)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { launchAtLogin.refresh() }
    }
}

struct RunnerSettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                RunnerPreview(
                    runner: Runner.builtIn(id: settings.runnerID),
                    speed: settings.previewSpeed,
                    flipped: settings.isFlippedHorizontally
                )
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                LabeledContent("Preview Speed") {
                    Slider(value: $settings.previewSpeed, in: Double(RunnerSpeed.minimum)...Double(RunnerSpeed.maximum))
                        .frame(width: 180)
                }
            }
            Section {
                Picker("Runner", selection: $settings.runnerID) {
                    ForEach(Runner.builtIns, id: \.id) { runner in
                        Text(runner.name).tag(runner.id)
                    }
                }
                Toggle("Flip horizontally", isOn: $settings.isFlippedHorizontally)
                Toggle("Slow down under load", isOn: $settings.speedDecreasesUnderLoad)
                Toggle("Show CPU usage in menu bar", isOn: $settings.showsCPUUsage)
            }
        }
        .formStyle(.grouped)
    }
}

struct MetricsSettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Memory", isOn: $settings.showsMemory)
                Toggle("Storage", isOn: $settings.showsStorage)
                Toggle("Battery", isOn: $settings.showsBattery)
                Toggle("Network", isOn: $settings.showsNetwork)
            } header: {
                Text("Dashboard")
            } footer: {
                Text("CPU is always shown. Battery appears only on Macs with a battery.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// 설정 창 미리보기. 메뉴바와 같은 규칙(속도 1 = 초당 2프레임)으로 프레임을 넘긴다.
private struct RunnerPreview: View {
    var runner: Runner
    var speed: Double
    var flipped: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5 / speed)) { context in
            let index = Int(context.date.timeIntervalSinceReferenceDate * 2 * speed) % max(runner.frames.count, 1)
            Image(decorative: runner.frames[index], scale: Runner.scale)
                .renderingMode(.template)
                .foregroundStyle(.primary)
                .scaleEffect(x: flipped ? -2 : 2, y: 2)
        }
    }
}
