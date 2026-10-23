import AppKit
import Foundation
import Testing
@testable import RunHam

@MainActor
struct CustomRunnerTests {
    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RunHamTests-\(UUID().uuidString)")
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
        #expect(Runner.resolve(id: runner.id, custom: reloaded).id == "hamster")
    }

    /// 왼쪽 위에 칠한 너비(marker + 1)로 어느 프레임인지 알아낸다
    private func marker(of image: CGImage) -> Int {
        let rep = NSBitmapImageRep(cgImage: image)
        var width = 0
        while width < image.width, (rep.colorAt(x: width, y: image.height - 1)?.alphaComponent ?? 0) > 0.5 { width += 1 }
        return width - 1
    }

    private func frame(_ marker: Int) -> CGImage {
        SpriteRenderer.render(width: 30, height: 36) { context in
            context.fill(CGRect(x: 0, y: 0, width: marker + 1, height: 2))
        }
    }

    @Test func savesFramesInEditedOrderAndUpdatesThem() throws {
        let storage = try makeDirectory()
        let store = CustomRunnerStore(directory: storage)
        let runner = try store.add(frames: [frame(2), frame(0), frame(1)], name: "  ", isTemplate: true)
        #expect(runner.name == L("customRunner.defaultName"))
        #expect(runner.frames.map(marker(of:)) == [2, 0, 1])

        // 순서를 바꾸고, 한 장을 빼고, 이름·색상을 고친다
        try store.update(id: runner.id, frames: [frame(1), frame(2)], name: "Bunny", isTemplate: false)
        let reloaded = CustomRunnerStore(directory: storage)
        let updated = try #require(reloaded.runner(id: runner.id))
        #expect(updated.name == "Bunny")
        #expect(!updated.isTemplate)
        #expect(updated.frames.map(marker(of:)) == [1, 2])
        #expect(!FileManager.default.fileExists(atPath: storage.appendingPathComponent(runner.id).appendingPathComponent("frame-2.png").path))

        // 규칙에 맞지 않으면 저장하지 않고 기존 프레임을 지킨다
        #expect(throws: CustomRunnerError.noFrames) { try reloaded.update(id: runner.id, frames: [], name: "X", isTemplate: true) }
        #expect(CustomRunnerStore(directory: storage).runner(id: runner.id)?.frames.count == 2)
    }

    @Test func draftReordersFrames() {
        let draft = CustomRunnerDraft(images: [frame(0), frame(1), frame(2), frame(3)])
        let ids = draft.frames.map(\.id)
        draft.move(ids[0], to: ids[2])
        #expect(draft.frames.map(\.id) == [ids[1], ids[2], ids[0], ids[3]])
        draft.move(ids[3], to: ids[1])
        #expect(draft.frames.map(\.id) == [ids[3], ids[1], ids[2], ids[0]])

        draft.selection = ids[2]
        draft.moveSelected(by: -1)
        #expect(draft.frames.map(\.id) == [ids[3], ids[2], ids[1], ids[0]])
        draft.moveSelected(by: -5)
        #expect(draft.frames.first?.id == ids[3])

        draft.reverse()
        #expect(draft.frames.map(\.id) == [ids[0], ids[1], ids[2], ids[3]])
        draft.removeSelected()
        #expect(draft.frames.map(\.id) == [ids[0], ids[1], ids[3]])
        #expect(draft.selection == ids[3])
    }
}
