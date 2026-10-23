import AppKit
import Foundation
import Testing
@testable import RunCatClone

@MainActor
struct CustomRunnerTests {
    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RunCatCloneTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// width×height 크기의 PNG. 왼쪽 위 n 픽셀을 칠해 프레임마다 내용이 다르게 한다.
    private func writePNG(width: Int, height: Int, marker: Int = 0, to url: URL) throws {
        let image = SpriteRenderer.render(width: width, height: height) { context in
            context.fill(CGRect(x: 0, y: 0, width: marker + 1, height: 2))
        }
        try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!.write(to: url)
    }

    @Test func framesAreReadInNaturalFileNameOrder() throws {
        let folder = try makeDirectory()
        for index in [10, 2, 0, 1] {
            try writePNG(width: 40, height: 36, marker: index, to: folder.appendingPathComponent("run-frame-\(index).png"))
        }
        try Data("not an image".utf8).write(to: folder.appendingPathComponent("notes.txt"))
        let names = try CustomRunnerImporter.frameURLs(in: folder).map(\.lastPathComponent)
        #expect(names == ["run-frame-0.png", "run-frame-1.png", "run-frame-2.png", "run-frame-10.png"])
    }

    @Test func rejectsFramesOutsideTheRules() throws {
        let folder = try makeDirectory()
        let tall = folder.appendingPathComponent("tall.png")
        let wide = folder.appendingPathComponent("wide.png")
        let jpeg = folder.appendingPathComponent("photo.png")
        try writePNG(width: 40, height: 40, to: tall)
        try writePNG(width: 120, height: 36, to: wide)
        let image = SpriteRenderer.render(width: 40, height: 36) { _ in }
        try NSBitmapImageRep(cgImage: image).representation(using: .jpeg, properties: [:])!.write(to: jpeg)

        #expect(throws: CustomRunnerError.invalidFrame("tall.png")) { try CustomRunnerImporter.loadFrames(from: [tall]) }
        #expect(throws: CustomRunnerError.invalidFrame("wide.png")) { try CustomRunnerImporter.loadFrames(from: [wide]) }
        #expect(throws: CustomRunnerError.invalidFrame("photo.png")) { try CustomRunnerImporter.loadFrames(from: [jpeg]) }
        #expect(throws: CustomRunnerError.noFrames) { try CustomRunnerImporter.loadFrames(from: []) }
    }

    @Test func limitsFrameCount() throws {
        let folder = try makeDirectory()
        let frame = folder.appendingPathComponent("frame.png")
        try writePNG(width: 20, height: 36, to: frame)
        let urls = Array(repeating: frame, count: CustomRunnerImporter.maxFrames + 1)
        #expect(throws: CustomRunnerError.tooManyFrames) { try CustomRunnerImporter.loadFrames(from: urls) }
        #expect(try CustomRunnerImporter.loadFrames(from: Array(urls.dropLast())).count == CustomRunnerImporter.maxFrames)
    }

    @Test func suggestsNameFromFolder() {
        #expect(CustomRunnerImporter.suggestedName(for: URL(fileURLWithPath: "/tmp/dolphin-frames")) == "dolphin")
        #expect(CustomRunnerImporter.suggestedName(for: URL(fileURLWithPath: "/tmp/Ghost")) == "Ghost")
    }

    @Test func storePersistsCopiesAndRemovesOnlyItsCopy() throws {
        let source = try makeDirectory()
        for index in 0..<3 {
            try writePNG(width: 50, height: 36, marker: index, to: source.appendingPathComponent("frame-\(index).png"))
        }
        let storage = try makeDirectory()
        let store = CustomRunnerStore(directory: storage)
        let runner = try store.add(folder: source, name: "Ghost", isTemplate: false)
        #expect(runner.id.hasPrefix(CustomRunnerStore.idPrefix))
        #expect(runner.name == "Ghost")
        #expect(runner.frames.count == 3)
        #expect(runner.pointSize == CGSize(width: 25, height: 18))
        #expect(runner.cycleDuration == 1.5)
        #expect(!runner.isTemplate)

        // 같은 이름은 숫자를 붙인다
        #expect(try store.add(folder: source, name: "Ghost").name == "Ghost 2")

        // 다시 열어도 그대로
        let reloaded = CustomRunnerStore(directory: storage)
        #expect(reloaded.runners.map(\.name) == ["Ghost", "Ghost 2"])
        #expect(Runner.resolve(id: runner.id, custom: reloaded).name == "Ghost")

        reloaded.setTemplate(true, id: runner.id)
        #expect(CustomRunnerStore(directory: storage).runner(id: runner.id)?.isTemplate == true)

        reloaded.remove(id: runner.id)
        #expect(!FileManager.default.fileExists(atPath: storage.appendingPathComponent(runner.id).path))
        #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent("frame-0.png").path))
        #expect(Runner.resolve(id: runner.id, custom: reloaded).id == "cat")
    }

    /// 사용자의 실제 RunCat Neo 커스텀 러너(돌고래)가 있으면 그대로 불러와지는지 확인한다.
    @Test(.enabled(if: FileManager.default.fileExists(atPath: "/path/to/dolphin-frames")))
    func importsRunCatNeoDolphinRunner() throws {
        let store = CustomRunnerStore(directory: try makeDirectory())
        let runner = try store.add(folder: URL(fileURLWithPath: "/path/to/dolphin-frames"))
        #expect(runner.name == "dolphin")
        #expect(runner.frames.count == 9)
        #expect(runner.pointSize == CGSize(width: 45, height: 18))
        #expect(runner.cycleDuration == 4.5)
    }
}
