import Foundation
import Testing
@testable import RunHam

struct CustomMetricsDocumentTests {
    @Test func decodesDocumentAndClampsNormalizedValue() throws {
        let json = """
        {
          "title": "Example",
          "metrics": [
            { "title": "Status", "formattedValue": "OK" },
            { "title": "Usage", "formattedValue": "142%", "normalizedValue": 1.42 }
          ],
          "lastUpdatedDate": "2026-06-05T04:50:40Z"
        }
        """
        let document = try CustomMetricsDocument.decode(Data(json.utf8))
        #expect(document.title == "Example")
        #expect(document.resolvedSymbol == CustomMetricsDocument.defaultSymbol)
        #expect(document.metrics[0].normalizedValue == nil)
        #expect(document.metrics[1].normalizedValue == 1)
        #expect(document.lastUpdatedDate == Date(timeIntervalSince1970: 1_780_635_040))
    }

    @Test func acceptsFractionalSeconds() throws {
        let json = #"{"title":"T","metrics":[],"lastUpdatedDate":"2026-06-05T04:50:40.250Z"}"#
        #expect(try CustomMetricsDocument.decode(Data(json.utf8)).metrics.isEmpty)
    }

    @Test func rejectsMissingRequiredFields() {
        let json = #"{"title":"T","metrics":[]}"#
        #expect(throws: (any Error).self) { try CustomMetricsDocument.decode(Data(json.utf8)) }
    }

    @Test func bundledSampleIsValid() throws {
        let sample = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../docs/custom-metrics-sample.json")
        #expect(try CustomMetricsStore.read(sample).metrics.count == 3)
    }
}

@MainActor
struct CustomMetricsStoreTests {
    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RunHamTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeStore() -> CustomMetricsStore {
        let suite = "RunHamTests.\(UUID().uuidString)"
        return CustomMetricsStore(defaults: UserDefaults(suiteName: suite)!)
    }

    private func write(_ title: String, to url: URL) throws {
        let json = #"{"title":"\#(title)","metrics":[],"lastUpdatedDate":"2026-06-05T04:50:40Z"}"#
        // 원자적 쓰기(임시 파일 → rename)로 inode 가 바뀌는 경우까지 확인한다.
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".tmp-\(UUID().uuidString)")
        try Data(json.utf8).write(to: temporary)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    }

    @Test func addRejectsInvalidFilesAndDuplicates() throws {
        let directory = try makeDirectory()
        let store = makeStore()
        let invalid = directory.appendingPathComponent("invalid.json")
        try Data("{".utf8).write(to: invalid)
        #expect(throws: CustomMetricsError.invalidFormat) { try store.add(invalid) }
        #expect(throws: CustomMetricsError.unreadable) { try store.add(directory.appendingPathComponent("missing.json")) }

        let valid = directory.appendingPathComponent("valid.json")
        try write("First", to: valid)
        try store.add(valid)
        #expect(throws: CustomMetricsError.alreadyAdded) { try store.add(valid) }
        store.sources.forEach { store.remove($0.id) }
    }

    @Test func reloadsOnAtomicWriteAndKeepsLastGoodSnapshotOnFailure() async throws {
        let directory = try makeDirectory()
        let store = makeStore()
        let file = directory.appendingPathComponent("metrics.json")
        try write("First", to: file)
        try store.add(file)
        let id = try #require(store.sources.first?.id)

        try write("Second", to: file)
        try await Task.sleep(for: .milliseconds(800))
        #expect(store.snapshots[id]?.title == "Second")

        try Data("not json".utf8).write(to: file)
        try await Task.sleep(for: .milliseconds(800))
        #expect(store.failedIDs.contains(id))
        #expect(store.snapshots[id]?.title == "Second")

        store.remove(id)
        #expect(store.sources.isEmpty)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }
}
