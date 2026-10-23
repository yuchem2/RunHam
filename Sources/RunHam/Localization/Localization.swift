import Foundation
import Observation
import SwiftUI

/// 앱 안에서 고르는 표시 언어. `code == nil` 이면 macOS 언어 설정을 따른다.
///
/// 지원 언어는 코드에 적지 않고 리소스 번들의 `<code>.lproj` 폴더에서 찾는다.
/// 새 언어는 `Resources/<code>.lproj/Localizable.strings` 를 추가하기만 하면 된다.
struct AppLanguage: Hashable, Identifiable, Sendable {
    /// 언어 코드(en, ko, ja, zh-Hans …). nil 은 시스템 설정.
    let code: String?

    static let system = AppLanguage(code: nil)
    static let developmentCode = "en"

    var id: String { code ?? "system" }

    /// 저장용 문자열 ↔ 값
    var storageValue: String { code ?? "system" }

    init(code: String?) {
        self.code = code
    }

    init(storageValue: String) {
        self.init(code: storageValue == "system" ? nil : storageValue)
    }

    /// 시스템 설정 + 번들에 들어 있는 모든 언어(개발 언어가 먼저, 나머지는 코드 순)
    static var available: [AppLanguage] {
        let codes = Localization.availableCodes.sorted { lhs, rhs in
            if lhs == developmentCode { return true }
            if rhs == developmentCode { return false }
            return lhs < rhs
        }
        return [.system] + codes.map(AppLanguage.init(code:))
    }

    /// 언어 이름은 그 언어로 적는다(다른 언어 화면에서도 자기 언어를 찾을 수 있게).
    var displayName: String {
        guard let code else { return L("language.system") }
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forIdentifier: code) ?? code
        return name.prefix(1).uppercased(with: locale) + name.dropFirst()
    }
}

/// 현재 언어의 문자열 테이블과 Locale. 재시작 없이 언어를 바꿀 수 있도록 번들을 직접 고른다.
///
/// `language` 는 관찰 가능해서 SwiftUI 화면은 `LocalizedRoot` 로 감싸 두면 언어가 바뀔 때 다시 그려진다.
/// 문자열 조회는 어느 스레드에서나 할 수 있게 잠금으로 보호한다(오류 메시지 등 MainActor 밖에서도 쓴다).
@Observable
final class Localization: @unchecked Sendable {
    static let shared = Localization()

    /// SwiftPM 이 만드는 리소스 번들. .app 안(Contents/Resources)에 있으면 그것을, 개발 실행·테스트에선 Bundle.module 을 쓴다.
    static let resources: Bundle = {
        if let url = Bundle.main.url(forResource: "RunHam_RunHam", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()

    /// 번들에 들어 있는 언어 코드. lproj 폴더 이름에서 찾는다.
    static var availableCodes: [String] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: resources.resourceURL ?? resources.bundleURL, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { $0.pathExtension == "lproj" && $0.deletingPathExtension().lastPathComponent != "Base" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    @ObservationIgnored private let lock = NSLock()
    @ObservationIgnored private var table: Bundle
    @ObservationIgnored private let fallback: Bundle
    @ObservationIgnored private var currentLocale: Locale

    var language: AppLanguage = .system {
        didSet { apply(language) }
    }

    private init() {
        let development = Self.table(for: AppLanguage.developmentCode) ?? Self.resources
        table = development
        fallback = development
        currentLocale = Locale(identifier: AppLanguage.developmentCode)
        apply(.system)
    }

    var locale: Locale {
        lock.withLock { currentLocale }
    }

    /// 현재 테이블에 없는 키는 개발 언어(영어)로, 그마저 없으면 키를 그대로 돌려준다.
    func string(_ key: String) -> String {
        lock.withLock {
            let missing = "\u{0}"
            let value = table.localizedString(forKey: key, value: missing, table: nil)
            if value != missing { return value }
            return fallback.localizedString(forKey: key, value: key, table: nil)
        }
    }

    /// 실제로 적용될 언어 코드. 시스템 설정이면 macOS 선호 언어 중 번들에 있는 첫 언어.
    static func resolvedCode(for language: AppLanguage, preferences: [String] = Locale.preferredLanguages) -> String {
        if let code = language.code, availableCodes.contains(code) { return code }
        return Bundle.preferredLocalizations(from: availableCodes, forPreferences: preferences).first ?? AppLanguage.developmentCode
    }

    private func apply(_ language: AppLanguage) {
        let code = Self.resolvedCode(for: language)
        let bundle = Self.table(for: code) ?? fallback
        lock.withLock {
            table = bundle
            currentLocale = Locale(identifier: code)
        }
    }

    private static func table(for code: String) -> Bundle? {
        resources.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:))
    }
}

/// 현지화 문자열.
func L(_ key: String) -> String {
    Localization.shared.string(key)
}

/// 형식 인자가 있는 현지화 문자열. 숫자 표기는 현재 언어의 Locale 을 따른다.
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: Localization.shared.string(key), locale: Localization.shared.locale, arguments: arguments)
}

/// 언어가 바뀌면 안쪽 화면 전체를 새로 만들고, 날짜 등 Locale 을 따르는 표기도 맞춘다.
struct LocalizedRoot<Content: View>: View {
    var localization = Localization.shared
    @ViewBuilder var content: Content

    var body: some View {
        content
            .id(localization.language)
            .environment(\.locale, localization.locale)
    }
}
