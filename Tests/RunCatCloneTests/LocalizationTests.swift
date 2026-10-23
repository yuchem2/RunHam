import Foundation
import Testing
@testable import RunCatClone

/// 새 언어를 추가해도 깨지지 않도록 모든 문자열 테이블을 개발 언어(영어) 기준으로 검사한다.
struct LocalizationTests {
    private static func table(_ code: String) throws -> [String: String] {
        let url = try #require(Localization.resources.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: code))
        return try #require(NSDictionary(contentsOf: url) as? [String: String])
    }

    /// 형식 지정자를 위치별 타입으로 정리한다. `%1$@` 와 `%@` 를 같은 기준으로 비교하기 위함.
    private static func placeholders(in text: String) -> [Int: Character] {
        let pattern = /%(?:(\d+)\$)?[-+ #0]*\d*(?:\.\d+)?(?:l{1,2}|h{1,2}|q|z|t|j)?([@dDiuUxXoOfFeEgGcCsSpaA%])/
        var result: [Int: Character] = [:]
        var next = 1
        for match in text.matches(of: pattern) {
            let type = Character(String(match.output.2))
            guard type != "%" else { continue }
            let index = match.output.1.flatMap { Int($0) } ?? next
            next = index + 1
            // %d 와 %ld 처럼 정수 계열은 같은 것으로 본다.
            result[index] = "dDiuUxXoO".contains(type) ? "d" : type
        }
        return result
    }

    @Test func everyLanguageHasTheSameKeysAsEnglish() throws {
        let english = try Self.table(AppLanguage.developmentCode)
        #expect(Localization.availableCodes.count >= 2)
        for code in Localization.availableCodes where code != AppLanguage.developmentCode {
            let table = try Self.table(code)
            let missing = Set(english.keys).subtracting(table.keys)
            let extra = Set(table.keys).subtracting(english.keys)
            #expect(missing.isEmpty, "\(code).lproj 에 없는 키: \(missing.sorted())")
            #expect(extra.isEmpty, "\(code).lproj 에만 있는 키: \(extra.sorted())")
        }
    }

    @Test func everyLanguageKeepsFormatPlaceholders() throws {
        let english = try Self.table(AppLanguage.developmentCode)
        for code in Localization.availableCodes where code != AppLanguage.developmentCode {
            let table = try Self.table(code)
            for (key, value) in english {
                guard let translated = table[key] else { continue }
                #expect(
                    Self.placeholders(in: translated) == Self.placeholders(in: value),
                    "\(code).lproj \"\(key)\" 의 형식 지정자가 영어와 다릅니다: \(translated)"
                )
            }
        }
    }

    /// 코드에서 쓰는 키는 모두 영어 테이블에 있어야 하고, 테이블의 키는 모두 어딘가에서 쓰여야 한다.
    @Test func sourceKeysMatchTheEnglishTable() throws {
        let english = try Self.table(AppLanguage.developmentCode)
        let prefixes = Set(english.keys.compactMap { $0.split(separator: ".").first.map(String.init) })
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../Sources/RunCatClone")
            .standardizedFileURL
        let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }

        var used = Set<String>()
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            // SF Symbol 이름("network.slash") 같은 다른 점 표기 문자열과 섞이지 않게 키를 넘기는 줄만 본다.
            for line in text.split(separator: "\n") where line.contains("L(") || line.contains("key:") || line.contains("nameKey:") {
                for match in line.matches(of: /"([a-z][A-Za-z]*(?:\.[A-Za-z]+)+)"/) {
                    let candidate = String(match.output.1)
                    if let prefix = candidate.split(separator: ".").first, prefixes.contains(String(prefix)) {
                        used.insert(candidate)
                    }
                }
            }
        }
        #expect(used.subtracting(english.keys).isEmpty, "테이블에 없는 키: \(used.subtracting(english.keys).sorted())")
        #expect(Set(english.keys).subtracting(used).isEmpty, "쓰이지 않는 키: \(Set(english.keys).subtracting(used).sorted())")
    }

    @Test func systemLanguageFollowsPreferences() {
        #expect(Localization.resolvedCode(for: .system, preferences: ["ko-KR", "en-US"]) == "ko")
        #expect(Localization.resolvedCode(for: .system, preferences: ["en-GB"]) == "en")
        // 번들에 없는 언어를 선호하면 개발 언어로 떨어진다.
        #expect(Localization.resolvedCode(for: .system, preferences: ["xx"]) == "en")
        #expect(Localization.resolvedCode(for: AppLanguage(code: "ko")) == "ko")
        #expect(Localization.resolvedCode(for: AppLanguage(code: "xx"), preferences: ["en"]) == "en")
    }

    @Test func availableLanguagesComeFromBundle() {
        let available = AppLanguage.available
        #expect(available.first == .system)
        #expect(available.dropFirst().first?.code == AppLanguage.developmentCode)
        #expect(Set(available.compactMap(\.code)) == Set(Localization.availableCodes))
        #expect(AppLanguage(code: "en").displayName == "English")
        #expect(AppLanguage(code: "ko").displayName == "한국어")
        #expect(AppLanguage(storageValue: "system") == .system)
        #expect(AppLanguage(storageValue: AppLanguage(code: "ko").storageValue).code == "ko")
    }

    @Test func switchingLanguageAppliesImmediately() {
        let localization = Localization.shared
        let original = localization.language
        defer { localization.language = original }

        localization.language = AppLanguage(code: "ko")
        #expect(L("menu.settings") == "설정…")
        #expect(L("dashboard.memory.used", "1 GB", "8 GB") == "8 GB 중 1 GB 사용")
        #expect(L("battery.cycles", 12) == "충전 횟수 12회")
        #expect(localization.locale.identifier == "ko")

        localization.language = AppLanguage(code: "en")
        #expect(L("menu.settings") == "Settings…")
        #expect(L("dashboard.memory.used", "1 GB", "8 GB") == "1 GB used of 8 GB")
        // 없는 키는 키 그대로 돌려준다.
        #expect(L("does.not.exist") == "does.not.exist")
    }
}
