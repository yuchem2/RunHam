import Foundation

/// 앱 이름을 RunCat Clone → RunHam 으로 바꾸면서 번들 ID 가 달라져 설정이 비어 보이지 않도록,
/// 처음 실행할 때 한 번만 이전 설정과 커스텀 러너 폴더를 옮긴다.
/// 선택한 러너는 옮기지 않아 새 기본 러너(햄스터)로 시작한다.
enum LegacyMigration {
    static let legacyDomain = "dev.personal.RunCatClone"
    static let legacySupportFolder = "RunCatClone"
    static let doneKey = "MIGRATED_FROM_RUNCAT_CLONE"
    static let skippedKeys: Set<String> = ["RUNNER_ID"]

    static func run(
        defaults: UserDefaults = .standard,
        legacyDomain: String = Self.legacyDomain,
        fileManager: FileManager = .default,
        movesRunners: Bool = true
    ) {
        guard !defaults.bool(forKey: doneKey) else { return }
        defer { defaults.set(true, forKey: doneKey) }

        if let legacy = defaults.persistentDomain(forName: legacyDomain) {
            for (key, value) in legacy where !skippedKeys.contains(key) && defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }

        guard movesRunners else { return }
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let legacyRunners = support.appendingPathComponent("\(legacySupportFolder)/Runners", isDirectory: true)
        let runners = CustomRunnerStore.defaultDirectory
        if fileManager.fileExists(atPath: legacyRunners.path), !fileManager.fileExists(atPath: runners.path) {
            try? fileManager.createDirectory(at: runners.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fileManager.moveItem(at: legacyRunners, to: runners)
        }
    }
}
