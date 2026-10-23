import Foundation
import Observation

/// 등록한 Custom Metrics JSON 파일 목록과 각 파일의 마지막 정상 스냅샷.
/// 읽기에 실패하면 이전 스냅샷을 그대로 두고 실패 표시만 한다.
@MainActor
@Observable
final class CustomMetricsStore {
    struct Source: Codable, Identifiable, Equatable, Sendable {
        var id: UUID
        var path: String

        var url: URL { URL(fileURLWithPath: path) }
        var fileName: String { url.lastPathComponent }
    }

    private static let key = "CUSTOM_METRICS_SOURCES"

    private(set) var sources: [Source] = []
    private(set) var snapshots: [UUID: CustomMetricsDocument] = [:]
    private(set) var failedIDs: Set<UUID> = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var watchers: [UUID: FileWatcher] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([Source].self, from: data) {
            sources = saved
        }
        sources.forEach(startWatching)
    }

    /// 등록 전에 한 번 읽어 스키마를 검사한다.
    func add(_ url: URL) throws {
        let path = url.standardizedFileURL.path
        guard !sources.contains(where: { $0.path == path }) else { throw CustomMetricsError.alreadyAdded }
        let document = try Self.read(URL(fileURLWithPath: path))
        let source = Source(id: UUID(), path: path)
        sources.append(source)
        snapshots[source.id] = document
        save()
        startWatching(source)
    }

    /// 대시보드 카드만 없앤다. 디스크의 JSON 파일은 지우지 않는다.
    func remove(_ id: UUID) {
        watchers.removeValue(forKey: id)?.stop()
        sources.removeAll { $0.id == id }
        snapshots[id] = nil
        failedIDs.remove(id)
        save()
    }

    func reload(_ id: UUID) {
        guard let source = sources.first(where: { $0.id == id }) else { return }
        do {
            snapshots[id] = try Self.read(source.url)
            failedIDs.remove(id)
        } catch {
            failedIDs.insert(id)
        }
    }

    nonisolated static func read(_ url: URL) throws -> CustomMetricsDocument {
        guard let data = try? Data(contentsOf: url) else { throw CustomMetricsError.unreadable }
        do {
            return try CustomMetricsDocument.decode(data)
        } catch {
            throw CustomMetricsError.invalidFormat
        }
    }

    private func startWatching(_ source: Source) {
        let watcher = FileWatcher(path: source.path) { [weak self] in
            self?.reload(source.id)
        }
        watchers[source.id] = watcher
        watcher.start()
        reload(source.id)
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(sources), forKey: Self.key)
    }
}
