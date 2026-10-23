import AppKit
import SwiftUI

/// 드롭다운에서 여는 작은 정보 창(오픈소스 라이선스, 버그 리포트). 처음 열 때 만들고, 닫으면 통째로 버린다.
@MainActor
final class InfoWindowController {
    private let titleKey: String
    private let makeView: () -> AnyView
    private var window: NSWindow?
    private var closeObserver: NSObjectProtocol?

    init(titleKey: String, makeView: @escaping () -> AnyView) {
        self.titleKey = titleKey
        self.makeView = makeView
    }

    func show() {
        let window = self.window ?? makeWindow()
        window.title = L(titleKey)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let controller = NSHostingController(rootView: LocalizedRoot { makeView() })
        controller.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.release() }
        }
        return window
    }

    private func release() {
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
        closeObserver = nil
        window?.contentViewController = nil
        window = nil
    }
}

// MARK: - 오픈소스 라이선스

/// 참고한 오픈소스와 그 라이선스 전문
struct LicensesView: View {
    struct Entry: Identifiable {
        var id: String { name }
        var name: String
        var copyright: String
        var license: String
        var url: URL
        var key: String
    }

    static let entries: [Entry] = [
        Entry(
            name: "RunCat Neo",
            copyright: "Copyright 2026 Kyome22 (Takuto Nakamura)",
            license: "Apache License 2.0",
            url: URL(string: "https://github.com/runcat-dev/RunCatNeo")!,
            key: "licenses.runCatNeo.usage"
        ),
    ]

    static var apacheLicenseText: String {
        Localization.resources.url(forResource: "Apache-2.0", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("licenses.intro"))
                .font(.callout)
                .foregroundStyle(.secondary)
            ForEach(Self.entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.name).font(.headline)
                        Spacer()
                        Link(L("licenses.source"), destination: entry.url).font(.caption)
                    }
                    Text(entry.copyright).font(.caption)
                    Text(entry.license).font(.caption).foregroundStyle(.secondary)
                    Text(L(entry.key)).font(.caption).foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
            Text(L("licenses.fullText")).font(.subheadline.weight(.medium))
            ScrollView {
                Text(Self.apacheLicenseText)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 220)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
        }
        .padding(20)
        // 라이선스 전문(한 줄 76자)이 줄바꿈 없이 들어가는 폭
        .frame(width: 560)
    }
}

// MARK: - 버그 리포트

/// 문제를 알릴 때 붙일 환경 정보를 만들어 복사하게 한다.
struct BugReportView: View {
    /// 이슈를 받을 곳(GitHub 저장소의 새 이슈 화면). nil 이면 복사만 한다.
    static let issuesURL: URL? = URL(string: "https://github.com/yuchem2/RunHam/issues/new")

    var settings: AppSettings
    var customRunners: CustomRunnerStore
    @State private var copied = false

    var body: some View {
        let report = BugReport.text(settings: settings, customRunners: customRunners)
        VStack(alignment: .leading, spacing: 12) {
            Text(L("bugReport.intro"))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                Text(report)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 150)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
            HStack {
                if copied {
                    Label(L("bugReport.copied"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Spacer()
                if let url = Self.issuesURL {
                    Link(L("bugReport.openIssues"), destination: url)
                }
                Button(L("bugReport.copy")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report, forType: .string)
                    copied = true
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

enum BugReport {
    @MainActor
    static func text(settings: AppSettings, customRunners: CustomRunnerStore) -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "dev"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let runner = Runner.resolve(id: settings.runnerID, custom: customRunners)
        return [
            "RunHam \(version) (\(build))",
            "macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            "Mac: \(hardwareModel()) · \(architecture)",
            "Language: \(Localization.shared.language.code ?? "system (\(Localization.resolvedCode(for: .system)))")",
            "Runner: \(runner.isCustom ? "custom (\(runner.frames.count) frames)" : runner.id)",
            "Metrics Bar: \(settings.showsMetricsBar ? "on" : "off")",
            "Update interval: \(Int(settings.updateInterval))s",
        ].joined(separator: "\n")
    }

    private static func hardwareModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "unknown" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private static var architecture: String {
        #if arch(arm64)
        "Apple silicon"
        #else
        "Intel"
        #endif
    }
}
