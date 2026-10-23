import AppKit
import SwiftUI

/// 개발용: 화면 녹화 권한 없이도 결과물을 확인할 수 있도록 러너 프레임과 화면을 PNG 로 내보낸다.
/// `RunHam --export-previews <dir>`, `RunHam --export-app-icon <AppIcon.iconset>`
@MainActor
enum DevExport {
    static func run(arguments: [String]) -> Bool {
        if let flag = arguments.firstIndex(of: "--export-app-icon"), flag + 1 < arguments.count {
            do {
                try exportAppIcon(to: URL(fileURLWithPath: arguments[flag + 1], isDirectory: true))
            } catch {
                FileHandle.standardError.write(Data("icon export failed: \(error)\n".utf8))
            }
            return true
        }
        guard let flag = arguments.firstIndex(of: "--export-previews"), flag + 1 < arguments.count else { return false }
        let directory = URL(fileURLWithPath: arguments[flag + 1], isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try exportFrames(to: directory)
            try exportViews(to: directory)
        } catch {
            FileHandle.standardError.write(Data("export failed: \(error)\n".utf8))
        }
        return true
    }

    /// iconutil 이 읽는 .iconset 폴더(16~512pt, 1x·2x)
    private static func exportAppIcon(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
                try png(NSBitmapImageRep(cgImage: AppIconRenderer.render(pixels: points * scale))).write(to: directory.appendingPathComponent(name))
            }
        }
    }

    private static func exportFrames(to directory: URL) throws {
        for runner in Runner.builtIns {
            for (index, frame) in runner.frames.enumerated() {
                try png(NSBitmapImageRep(cgImage: frame)).write(to: directory.appendingPathComponent("\(runner.id)-frame-\(index).png"))
            }
            for (index, frame) in runner.previewFrames.enumerated() where !runner.isPixelArt {
                try png(NSBitmapImageRep(cgImage: frame)).write(to: directory.appendingPathComponent("\(runner.id)-preview-frame-\(index).png"))
            }
        }
    }

    private static func exportViews(to directory: URL) throws {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "RunHam.DevExport")!)
        let customMetrics = CustomMetricsStore(defaults: UserDefaults(suiteName: "RunHam.DevExport")!)
        let sample = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../docs/custom-metrics-sample.json").standardizedFileURL
        if FileManager.default.fileExists(atPath: sample.path) {
            try? customMetrics.add(sample)
        }
        // 미리보기에선 사용자 데이터를 건드리지 않도록 임시 폴더의 러너 목록을 쓴다
        let customRunners = CustomRunnerStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("RunHam-DevExport-\(UUID().uuidString)"))
        if let folder = ProcessInfo.processInfo.environment["EXPORT_CUSTOM_RUNNER"] {
            try? customRunners.add(folder: URL(fileURLWithPath: folder))
        }
        let monitor = MetricsMonitor()
        monitor.sample()
        // 네트워크 연결 상태(NWPathMonitor)는 메인 큐 콜백으로 오므로 런루프를 돌리며 기다린다.
        for _ in 0..<3 {
            RunLoop.main.run(until: Date().addingTimeInterval(1))
            monitor.sample()
        }
        let views: [(String, () -> AnyView)] = [
            ("dashboard", { AnyView(DashboardView(metrics: monitor.metrics, settings: settings, customMetrics: customMetrics)) }),
            ("settings-general", { AnyView(GeneralSettingsView(settings: settings, launchAtLogin: LaunchAtLogin())) }),
            ("settings-runner", { AnyView(RunnerSettingsView(settings: settings, metrics: monitor.metrics, customRunners: customRunners)) }),
            ("settings-metrics", { AnyView(MetricsSettingsView(settings: settings, customMetrics: customMetrics)) }),
        ]
        defer { customMetrics.sources.forEach { customMetrics.remove($0.id) } }
        try exportMetricsBars(metrics: monitor.metrics, customMetrics: customMetrics, to: directory)
        // 언어마다 화면을 새로 만들어 그린다(문자열은 body 에서 읽으므로 언어를 바꾼 뒤 만들어야 한다).
        let original = Localization.shared.language
        defer { Localization.shared.language = original }
        for code in Localization.availableCodes.sorted() {
            Localization.shared.language = AppLanguage(code: code)
            for (name, makeView) in views {
                // 대시보드는 투명 배경이라 다크 캡처에선 글자가 보이지 않아 라이트만 내보낸다.
                let appearances: [NSAppearance.Name] = name == "dashboard" ? [.aqua] : [.aqua, .darkAqua]
                for appearance in appearances {
                    let suffix = appearance == .aqua ? "light" : "dark"
                    let rep = snapshot(makeView(), appearance: NSAppearance(named: appearance)!)
                    try png(rep).write(to: directory.appendingPathComponent("\(name)-\(code)-\(suffix).png"))
                }
            }
            try exportNotice(to: directory.appendingPathComponent("metricsbar-notice-\(code).png"))
        }
    }

    /// 메트릭스 바 이미지를 밝은/어두운 메뉴바 색 위에 4배 확대해서 그린다.
    private static func exportMetricsBars(metrics: SystemMetrics, customMetrics: CustomMetricsStore, to directory: URL) throws {
        var everything = MetricsBarConfiguration(showsCPU: true, showsMemory: true, showsStorage: true, showsBattery: true, showsNetwork: true)
        everything.visibleCustomMetricsSourceIDs = Set(customMetrics.sources.map(\.id))
        let cases: [(String, MetricsBarConfiguration)] = [
            ("cpu", .default),
            ("all", everything),
            ("empty", MetricsBarConfiguration(showsCPU: false)),
        ]
        for (name, configuration) in cases {
            let items = MetricsBarController.items(configuration: configuration, metrics: metrics, customMetrics: customMetrics)
            let image = MetricsBarRenderer.image(for: items)
            let zoom: CGFloat = 4
            let size = CGSize(width: (image.size.width + 16) * zoom, height: (image.size.height + 8) * 2 * zoom)
            let output = NSImage(size: size, flipped: false) { _ in
                for (index, (background, foreground)) in [(NSColor(white: 0.93, alpha: 1), NSColor.black), (NSColor(white: 0.15, alpha: 1), NSColor.white)].enumerated() {
                    let band = CGRect(x: 0, y: CGFloat(1 - index) * size.height / 2, width: size.width, height: size.height / 2)
                    background.setFill()
                    band.fill()
                    let tinted = NSImage(size: image.size, flipped: false) { rect in
                        image.draw(in: rect)
                        foreground.set()
                        rect.fill(using: .sourceAtop)
                        return true
                    }
                    NSGraphicsContext.current?.imageInterpolation = .none
                    tinted.draw(in: CGRect(x: 8 * zoom, y: band.minY + 4 * zoom, width: image.size.width * zoom, height: image.size.height * zoom))
                }
                return true
            }
            guard let tiff = output.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { continue }
            try png(rep).write(to: directory.appendingPathComponent("metricsbar-\(name).png"))
        }
    }

    /// 메트릭스 바 노치 안내 경고창을 띄우지 않고 그대로 그린다.
    private static func exportNotice(to url: URL) throws {
        let alert = NSAlert()
        alert.messageText = L("metricsBar.notice.title")
        alert.informativeText = L("settings.metricsBar.notch")
        alert.addButton(withTitle: L("common.show"))
        alert.addButton(withTitle: L("common.cancel"))
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = L("common.dontShowAgain")
        alert.layout()
        guard let view = alert.window.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try png(rep).write(to: url)
    }

    static func snapshot(_ view: some View, appearance: NSAppearance) -> NSBitmapImageRep {
        let hosting = NSHostingView(rootView: view.fixedSize(horizontal: false, vertical: true))
        hosting.frame.size = hosting.fittingSize
        let window = NSWindow(contentRect: hosting.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = appearance
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        hosting.display()
        let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)!
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        return rep
    }

    private static func png(_ rep: NSBitmapImageRep) -> Data {
        rep.representation(using: .png, properties: [:])!
    }
}
