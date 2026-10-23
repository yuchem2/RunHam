import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// 저장소에 넣어 두는 러너 이미지와 README 화면을 만든다(개발용).
///
/// - `RunHam --export-runners <dir>`: 기본 러너 프레임(PNG, 높이 36px)과 미리보기 GIF → `Runners/`
/// - `RunHam --export-readme <dir>`: 샘플 수치로 그린 대시보드·설정 화면 → `Assets/readme/`
///
/// README 화면은 실제 측정값 대신 고정된 샘플 수치를 써서 IP 주소 같은 개인 정보가 찍히지 않는다.
@MainActor
enum Showcase {
    static func run(arguments: [String]) -> Bool {
        for (flag, export) in [("--export-runners", exportRunners), ("--export-readme", exportReadme)] as [(String, (URL) throws -> Void)] {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { continue }
            do {
                let directory = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try export(directory)
            } catch {
                FileHandle.standardError.write(Data("\(flag) failed: \(error)\n".utf8))
            }
            return true
        }
        return false
    }

    // MARK: - 러너

    /// 러너마다 폴더를 만들어 프레임 PNG(커스텀 러너·Runner Gallery 와 같은 이름 규칙)와
    /// 밝은/어두운 메뉴바 위 미리보기 GIF 를 넣는다.
    static func exportRunners(to directory: URL) throws {
        for runner in Runner.builtIns {
            let folder = directory.appendingPathComponent(runner.id, isDirectory: true)
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for (index, frame) in runner.frames.enumerated() {
                try png(frame).write(to: folder.appendingPathComponent("\(runner.id)-frame-\(index).png"))
            }
            for dark in [false, true] {
                try previewGIF(runner, dark: dark).write(to: folder.appendingPathComponent(dark ? "preview-dark.gif" : "preview-light.gif"))
            }
        }
        try png(SleepingHamsterSprite.image).write(to: directory.appendingPathComponent("sleeping-hamster.png"))
    }

    /// 메뉴바 색 바탕에 2배 크기(높이 36pt)로, 속도 2(조금 바쁜 Mac)에서 도는 모습
    private static func previewGIF(_ runner: Runner, dark: Bool, scale: CGFloat = 4) -> Data {
        let padding = CGSize(width: 6, height: 3)
        let size = CGSize(width: (runner.pointSize.width + padding.width * 2) * scale, height: (runner.pointSize.height + padding.height * 2) * scale)
        let background = dark ? CGColor(gray: 0.16, alpha: 1) : CGColor(gray: 0.93, alpha: 1)
        let ink = dark ? CGColor(gray: 1, alpha: 1) : CGColor(gray: 0, alpha: 1)
        let delay = 1 / (runner.baseFrameRate * 2)

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, runner.frames.count, nil)!
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in runner.previewFrames {
            let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.setFillColor(background)
            context.fill(CGRect(origin: .zero, size: size))
            context.interpolationQuality = runner.isPixelArt ? .none : .high
            let rect = CGRect(x: padding.width * scale, y: padding.height * scale,
                              width: CGFloat(frame.width) / CGFloat(frame.height) * runner.pointSize.height * scale,
                              height: runner.pointSize.height * scale)
            if runner.isTemplate {
                // 템플릿 러너는 알파만 마스크로 써서 메뉴바 글자색으로 칠한다
                context.saveGState()
                context.clip(to: rect, mask: frame)
                context.setFillColor(ink)
                context.fill(rect)
                context.restoreGState()
            } else {
                context.draw(frame, in: rect)
            }
            CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]] as CFDictionary)
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    // MARK: - README 화면

    static func exportReadme(to directory: URL) throws {
        // 맨 위 그림: 앱 아이콘과 크게 뛰는 기본 햄스터
        try png(AppIconRenderer.render(pixels: 256)).write(to: directory.appendingPathComponent("icon.png"))
        for dark in [false, true] {
            try previewGIF(Runner.builtIns[0], dark: dark, scale: 8).write(to: directory.appendingPathComponent(dark ? "hero-dark.gif" : "hero-light.gif"))
        }

        try write(runnerGuide(), to: directory.appendingPathComponent("runner-guide.png"))

        let suite = "RunHam.Showcase"
        UserDefaults().removePersistentDomain(forName: suite)
        let defaults = UserDefaults(suiteName: suite)!
        let settings = AppSettings(defaults: defaults)
        let customMetrics = CustomMetricsStore(defaults: defaults)
        let customRunners = CustomRunnerStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("RunHam-Showcase-\(UUID().uuidString)"))
        let metrics = sampleMetrics()

        let original = Localization.shared.language
        defer { Localization.shared.language = original }
        for code in ["en", "ko"] {
            Localization.shared.language = AppLanguage(code: code)
            for dark in [false, true] {
                let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)!
                let suffix = "\(code)-\(dark ? "dark" : "light")"
                let dashboard = DashboardView(metrics: metrics, settings: settings, customMetrics: customMetrics)
                    .background(dark ? Color(white: 0.17) : Color(white: 0.94))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                try write(snapshot(dashboard, appearance: appearance), to: directory.appendingPathComponent("dashboard-\(suffix).png"))

                let runnerSettings = RunnerSettingsView(settings: settings, metrics: metrics, customRunners: customRunners)
                try write(snapshot(runnerSettings, appearance: appearance), to: directory.appendingPathComponent("settings-runner-\(suffix).png"))

                let draft = CustomRunnerDraft(name: L("runner.hamster"), images: Runner.builtIns[0].frames)
                draft.selection = draft.frames[2].id
                let editor = CustomRunnerEditorView(draft: draft, onCancel: {}, onSave: {})
                    .background(Color(nsColor: .windowBackgroundColor))
                try write(snapshot(editor, appearance: appearance), to: directory.appendingPathComponent("custom-runner-\(suffix).png"))
            }
        }
    }

    /// 커스텀 러너 규격 안내 그림: 투명 바탕(체크무늬) 위 36px 높이 프레임들과 높이·바닥선 표시
    private static func runnerGuide() -> NSBitmapImageRep {
        let runner = Runner.builtIns[0]
        let zoom: CGFloat = 4
        let frameSize = CGSize(width: CGFloat(runner.frames[0].width) * zoom, height: 36 * zoom)
        let gap: CGFloat = 18, left: CGFloat = 70, top: CGFloat = 40, bottom: CGFloat = 46
        let count = runner.frames.count
        let size = CGSize(width: left + (frameSize.width + gap) * CGFloat(count) + 10, height: top + frameSize.height + bottom)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        defer { NSGraphicsContext.restoreGraphicsState() }
        let context = NSGraphicsContext.current!.cgContext
        NSColor.white.setFill()
        CGRect(origin: .zero, size: size).fill()
        let label: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: NSColor.darkGray]
        let accent = NSColor.systemOrange

        for index in 0..<count {
            let origin = CGPoint(x: left + CGFloat(index) * (frameSize.width + gap), y: bottom)
            // 투명 바탕을 나타내는 체크무늬
            let cell: CGFloat = 8
            for row in 0..<Int(frameSize.height / cell) {
                for column in 0..<Int(ceil(frameSize.width / cell)) where (row + column) % 2 == 0 {
                    NSColor(white: 0.9, alpha: 1).setFill()
                    CGRect(x: origin.x + CGFloat(column) * cell, y: origin.y + CGFloat(row) * cell,
                           width: min(cell, frameSize.width - CGFloat(column) * cell), height: cell).fill()
                }
            }
            context.interpolationQuality = .none
            context.draw(runner.frames[index], in: CGRect(origin: origin, size: frameSize))
            NSColor(white: 0.75, alpha: 1).setStroke()
            NSBezierPath(rect: CGRect(origin: origin, size: frameSize).insetBy(dx: 0.5, dy: 0.5)).stroke()
            ("frame-\(index).png" as NSString).draw(at: CGPoint(x: origin.x, y: origin.y - 22), withAttributes: label)
        }
        // 높이 36px 눈금
        accent.setStroke()
        let ruler = NSBezierPath()
        ruler.move(to: CGPoint(x: left - 22, y: bottom))
        ruler.line(to: CGPoint(x: left - 22, y: bottom + frameSize.height))
        for y in [bottom, bottom + frameSize.height] {
            ruler.move(to: CGPoint(x: left - 30, y: y))
            ruler.line(to: CGPoint(x: left - 14, y: y))
        }
        ruler.lineWidth = 2
        ruler.stroke()
        ("36px" as NSString).draw(at: CGPoint(x: 8, y: bottom + frameSize.height / 2 - 8),
                                  withAttributes: [.font: NSFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: accent])
        ("PNG · 36px tall · 10–100px wide · up to 30 frames · played in order" as NSString)
            .draw(at: CGPoint(x: left, y: size.height - 28), withAttributes: label)
        return rep
    }

    /// 화면에 찍힐 고정 샘플 수치(실제 Mac 의 값과 IP 주소를 쓰지 않는다)
    private static func sampleMetrics() -> SystemMetrics {
        let metrics = SystemMetrics()
        for step in 0..<SystemMetrics.historyLength {
            let t = Double(step)
            let percent = 18 + 9 * sin(t / 3.2) + 6 * sin(t / 1.3) + (step > 28 && step < 33 ? 22 : 0)
            metrics.appendCPU(CPUSnapshot(percent: percent, user: percent * 0.62, system: percent * 0.38, idle: 100 - percent))
        }
        metrics.memory = MemoryUsage(total: 16 << 30, app: 6_400 << 20, wired: 2_300 << 20, compressed: 1_100 << 20)
        metrics.storage = StorageUsage(total: 494_380_000_000, available: 211_640_000_000)
        metrics.battery = BatteryStatus(level: 86, isCharging: true, isPluggedIn: true, cycleCount: 132, health: 0.97)
        metrics.isNetworkConnected = true
        metrics.networkInterface = "wifi"
        metrics.networkBSDName = "en0"
        metrics.addresses = NetworkAddresses(ipv4: "192.168.0.10", ipv6: nil)
        metrics.throughput = NetworkThroughput(received: 1_240_000, sent: 342_000)
        metrics.lastUpdated = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: Date())
        return metrics
    }

    // MARK: - 공통

    private static func snapshot(_ view: some View, appearance: NSAppearance) -> NSBitmapImageRep {
        DevExport.snapshot(LocalizedRoot { view }, appearance: appearance)
    }

    private static func write(_ rep: NSBitmapImageRep, to url: URL) throws {
        try rep.representation(using: .png, properties: [:])!.write(to: url)
    }

    private static func png(_ image: CGImage) -> Data {
        NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    }
}
