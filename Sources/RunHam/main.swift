import AppKit

if DevExport.run(arguments: CommandLine.arguments) || Showcase.run(arguments: CommandLine.arguments) {
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
