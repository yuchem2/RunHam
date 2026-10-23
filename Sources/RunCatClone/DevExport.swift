import AppKit
import SwiftUI

/// 개발용: 화면 녹화 권한 없이도 결과물을 확인할 수 있도록 러너 프레임과 화면을 PNG 로 내보낸다.
/// `RunCatClone --export-previews <dir>`
@MainActor
enum DevExport {
    static func run(arguments: [String]) -> Bool {
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

    private static func exportFrames(to directory: URL) throws {
        for runner in Runner.builtIns {
            for (index, frame) in runner.frames.enumerated() {
                try png(NSBitmapImageRep(cgImage: frame)).write(to: directory.appendingPathComponent("\(runner.id)-frame-\(index).png"))
            }
        }
    }

    private static func exportViews(to directory: URL) throws {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "RunCatClone.DevExport")!)
        let views: [(String, AnyView)] = [
            ("settings-general", AnyView(GeneralSettingsView(settings: settings, launchAtLogin: LaunchAtLogin()))),
            ("settings-runner", AnyView(RunnerSettingsView(settings: settings))),
            ("settings-metrics", AnyView(MetricsSettingsView(settings: settings))),
        ]
        for (name, view) in views {
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                let suffix = appearance == .aqua ? "light" : "dark"
                let rep = snapshot(view.frame(width: 440), appearance: NSAppearance(named: appearance)!)
                try png(rep).write(to: directory.appendingPathComponent("\(name)-\(suffix).png"))
            }
        }
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
