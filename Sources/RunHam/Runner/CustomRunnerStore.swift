import AppKit
import Foundation
import Observation

/// RunCat Neo 와 같은 규칙의 커스텀 러너 프레임 오류
enum CustomRunnerError: LocalizedError, Equatable {
    case noFrames
    case invalidFrame(String)
    case tooManyFrames
    case savingFailed

    var errorDescription: String? {
        switch self {
        case .noFrames: L("error.customRunner.noFrames")
        case let .invalidFrame(fileName): L("error.customRunner.invalidFrame", fileName)
        case .tooManyFrames: L("error.customRunner.tooManyFrames", CustomRunnerImporter.maxFrames)
        case .savingFailed: L("error.customRunner.savingFailed")
        }
    }
}

/// PNG 프레임 폴더(또는 파일들)를 읽고 RunCat Neo 커스텀 러너 규칙으로 검사한다.
/// 규칙: PNG, 높이 36px(메뉴바 18pt @2x), 너비 10~100px, 1~30장. 파일 이름 순서(숫자는 크기 순)로 재생한다.
enum CustomRunnerImporter {
    static let frameHeight = 36
    static let frameWidths = 10...100
    static let maxFrames = 30

    /// 폴더 안의 PNG 파일을 파일 이름 순서로. `frame-2` 가 `frame-10` 보다 앞선다.
    static func frameURLs(in folder: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        return contents
            .filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func loadFrames(from urls: [URL]) throws -> [CGImage] {
        guard !urls.isEmpty else { throw CustomRunnerError.noFrames }
        guard urls.count <= maxFrames else { throw CustomRunnerError.tooManyFrames }
        return try urls.map { url in
            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                CGImageSourceGetType(source).map({ $0 as String == "public.png" }) == true,
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                image.height == frameHeight,
                frameWidths.contains(image.width)
            else { throw CustomRunnerError.invalidFrame(url.lastPathComponent) }
            return image
        }
    }

    /// 폴더 이름에서 러너 이름을 만든다(dolphin-frames → dolphin).
    static func suggestedName(for folder: URL) -> String {
        var name = folder.lastPathComponent
        for suffix in ["-frames", "_frames", " frames"] where name.lowercased().hasSuffix(suffix) {
            name = String(name.dropLast(suffix.count))
        }
        return name.isEmpty ? folder.lastPathComponent : name
    }
}

/// 사용자가 추가한 커스텀 러너 목록. 프레임은 앱 데이터 폴더에 복사해 두므로 원본 폴더를 옮겨도 된다.
///
/// `<Application Support>/RunHam/Runners/<id>/frame-<n>.png` 와 같은 폴더의 `runners.json` 에 저장한다.
@MainActor
@Observable
final class CustomRunnerStore {
    struct Record: Codable, Equatable, Identifiable, Sendable {
        var id: String
        var name: String
        var frameCount: Int
        var isTemplate: Bool
    }

    static let idPrefix = "custom-"

    private(set) var records: [Record] = []
    private(set) var runners: [Runner] = []

    @ObservationIgnored private let directory: URL
    @ObservationIgnored var onChange: (() -> Void)?

    init(directory: URL = CustomRunnerStore.defaultDirectory) {
        self.directory = directory
        load()
    }

    nonisolated static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RunHam/Runners", isDirectory: true)
    }

    func runner(id: String) -> Runner? {
        runners.first { $0.id == id }
    }

    /// 폴더의 PNG 프레임을 검사해 복사하고 러너로 등록한다. 이름이 겹치면 숫자를 붙인다.
    @discardableResult
    func add(folder: URL, name: String? = nil, isTemplate: Bool = true) throws -> Runner {
        let frames = try CustomRunnerImporter.loadFrames(from: CustomRunnerImporter.frameURLs(in: folder))
        let record = Record(
            id: Self.idPrefix + UUID().uuidString,
            name: uniqueName(name?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? CustomRunnerImporter.suggestedName(for: folder)),
            frameCount: frames.count,
            isTemplate: isTemplate
        )
        let folderURL = directory.appendingPathComponent(record.id, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            for (index, frame) in frames.enumerated() {
                guard let data = NSBitmapImageRep(cgImage: frame).representation(using: .png, properties: [:]) else {
                    throw CustomRunnerError.savingFailed
                }
                try data.write(to: folderURL.appendingPathComponent("frame-\(index).png"))
            }
            records.append(record)
            try save()
        } catch {
            try? FileManager.default.removeItem(at: folderURL)
            records.removeAll { $0.id == record.id }
            throw CustomRunnerError.savingFailed
        }
        rebuild()
        onChange?()
        return runner(id: record.id)!
    }

    /// 앱에 복사해 둔 프레임만 지운다(원본 폴더는 건드리지 않는다).
    func remove(id: String) {
        records.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(id, isDirectory: true))
        try? save()
        rebuild()
        onChange?()
    }

    /// 메뉴바 글자색으로 칠할지(템플릿) 원래 색을 유지할지
    func setTemplate(_ isTemplate: Bool, id: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isTemplate = isTemplate
        try? save()
        rebuild()
        onChange?()
    }

    private func uniqueName(_ base: String) -> String {
        let existing = Set(records.map(\.name))
        guard existing.contains(base) else { return base }
        var number = 2
        while existing.contains("\(base) \(number)") { number += 1 }
        return "\(base) \(number)"
    }

    private var listURL: URL { directory.appendingPathComponent("runners.json") }

    private func load() {
        guard let data = try? Data(contentsOf: listURL),
              let saved = try? JSONDecoder().decode([Record].self, from: data) else { return }
        records = saved
        rebuild()
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(records).write(to: listURL, options: .atomic)
    }

    /// 저장된 프레임을 다시 읽어 Runner 로 만든다. 읽지 못한 러너는 목록에서 빠진다.
    private func rebuild() {
        runners = records.compactMap { record in
            let folder = directory.appendingPathComponent(record.id, isDirectory: true)
            let urls = (0..<record.frameCount).map { folder.appendingPathComponent("frame-\($0).png") }
            guard let frames = try? CustomRunnerImporter.loadFrames(from: urls) else { return nil }
            return Runner(
                id: record.id,
                nameKey: "",
                frames: frames,
                isPixelArt: false,
                customName: record.name,
                isTemplate: record.isTemplate
            )
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
