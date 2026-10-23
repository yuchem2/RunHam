import AppKit

// 개발용: `RunCatClone --export-frames <dir>` 로 러너 프레임을 PNG 로 내보낸다.
if let flag = CommandLine.arguments.firstIndex(of: "--export-frames"), flag + 1 < CommandLine.arguments.count {
    let directory = URL(fileURLWithPath: CommandLine.arguments[flag + 1], isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for runner in Runner.builtIns {
        for (index, frame) in runner.frames.enumerated() {
            let data = NSBitmapImageRep(cgImage: frame).representation(using: .png, properties: [:])!
            try data.write(to: directory.appendingPathComponent("\(runner.id)-frame-\(index).png"))
        }
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
