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

/// 앱에 포함한 외부 오픈소스와 그 라이선스 전문. 지금은 외부 라이브러리를 쓰지 않아 빈 목록이다.
/// 패키지를 추가하면 `entries` 에 한 칸씩 더한다(라이선스 전문은 Resources/Licenses 에 두고 이름으로 읽는다).
struct LicensesView: View {
    struct Entry: Identifiable {
        var id: String { name }
        var name: String
        var copyright: String
        var license: String
        var url: URL
        /// Resources/Licenses/<licenseFile>.txt
        var licenseFile: String

        var licenseText: String {
            Localization.resources.url(forResource: licenseFile, withExtension: "txt")
                .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        }
    }

    static let entries: [Entry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if Self.entries.isEmpty {
                Label(L("licenses.empty"), systemImage: "checkmark.seal")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Self.entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.name).font(.headline)
                        Spacer()
                        Link(L("licenses.source"), destination: entry.url).font(.caption)
                    }
                    Text("\(entry.copyright) · \(entry.license)").font(.caption).foregroundStyle(.secondary)
                    ScrollView {
                        Text(entry.licenseText)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 160)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
                }
            }
        }
        .padding(20)
        // 라이선스 전문(한 줄 76자)이 줄바꿈 없이 들어가는 폭. 목록이 비면 안내 한 줄만 보이니 좁게.
        .frame(width: Self.entries.isEmpty ? 420 : 560)
    }
}

// MARK: - 문제 보고

/// 문제 보고: GitHub 새 이슈 화면을 열고, 본문에 환경 정보를 미리 채워 둔다.
enum BugReport {
    static let newIssueURL = URL(string: "https://github.com/yuchem2/RunHam/issues/new")!

    @MainActor
    static func open(settings: AppSettings, customRunners: CustomRunnerStore) {
        var components = URLComponents(url: newIssueURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "body", value: L("issue.body", text(settings: settings, customRunners: customRunners)))]
        NSWorkspace.shared.open(components.url ?? newIssueURL)
    }

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
