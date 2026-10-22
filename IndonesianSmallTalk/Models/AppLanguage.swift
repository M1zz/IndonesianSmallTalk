import Foundation

// MARK: - App Language

/// 앱이 다루는 6개 언어. 배우는 언어(learning)와 화면 언어(native) 모두 이 안에서 고른다.
/// rawValue 는 앱 번역(lproj)·콘텐츠 JSON 파일 이름과 같은 언어 코드.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case chinese = "zh-Hans"
    case spanish = "es"
    case indonesian = "id"

    var id: String { rawValue }

    /// TTS·STT 에 쓰는 지역 코드
    var speechCode: String {
        switch self {
        case .korean: return "ko-KR"
        case .english: return "en-US"
        case .japanese: return "ja-JP"
        case .chinese: return "zh-CN"
        case .spanish: return "es-ES"
        case .indonesian: return "id-ID"
        }
    }

    var flag: String {
        switch self {
        case .korean: return "🇰🇷"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .indonesian: return "🇮🇩"
        }
    }

    /// 그 언어로 쓴 언어 이름 (언어 고르는 목록에 같이 보여 준다)
    var endonym: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .indonesian: return "Bahasa Indonesia"
        }
    }

    /// 화면 언어로 쓴 언어 이름 (예: 영어 화면에서 .japanese → "Japanese")
    var localizedName: String {
        let locale = Locale(identifier: AppLanguage.uiCode)
        let name = locale.localizedString(forLanguageCode: rawValue == "zh-Hans" ? "zh" : rawValue) ?? endonym
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// 낱말 사이를 띄어 쓰지 않는 언어 (발음 비교를 글자 단위로 한다)
    var writesWithoutSpaces: Bool { self == .japanese || self == .chinese }

    /// 한국어 화면에서 쓰는 한글 발음 표기는 한국어 사용자에게만 보여 준다.
    static var showsHangulRomanization: Bool { native == .korean }

    // MARK: Current

    /// 화면 언어 = 앱이 실제로 띄운 번역. 지원하지 않는 언어의 기기는 영어로 뜬다.
    static let native: AppLanguage = {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return AppLanguage(localeCode: code) ?? .english
    }()

    /// 앱이 실제로 띄운 번역의 언어 코드 (예: "cs", "pt-BR"). 화면 언어(native)는 6개 안에서만 고르므로
    /// 그 밖의 번역(체코어 등)으로 뜬 화면에서 언어 이름 · 분류 이름을 그 말로 보여 주려면 이것을 쓴다.
    static let uiCode: String = Bundle.main.preferredLocalizations.first ?? "en"

    /// 지금 배우는 언어. 키보드 익스텐션도 읽어야 해서 App Group 기본값에 둔다.
    static var learning: AppLanguage {
        get {
            if let raw = LanguagePrefs.defaults.string(forKey: LanguagePrefs.learningKey),
               let lang = AppLanguage(rawValue: raw), lang != native {
                return lang
            }
            return LanguagePrefs.defaultLearning
        }
        set { LanguagePrefs.defaults.set(newValue.rawValue, forKey: LanguagePrefs.learningKey) }
    }

    /// 화면 언어를 뺀, 배울 수 있는 언어들
    static var learnable: [AppLanguage] { allCases.filter { $0 != native } }

    init?(localeCode code: String) {
        let lower = code.lowercased()
        if lower.hasPrefix("zh") { self = .chinese; return }
        let base = String(lower.prefix { $0 != "-" && $0 != "_" })
        guard let lang = AppLanguage.allCases.first(where: { $0.rawValue == base }) else { return nil }
        self = lang
    }
}

// MARK: - Preferences

enum LanguagePrefs {
    static let learningKey = "learningLanguage"
    static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    static var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    /// 한 번도 고르지 않았을 때: 기존(한국어) 사용자는 하던 인도네시아어 그대로,
    /// 다른 나라 사용자는 영어(영어 사용자는 한국어)부터.
    static var defaultLearning: AppLanguage {
        switch AppLanguage.native {
        case .korean: return .indonesian
        case .english: return .korean
        default: return .english
        }
    }

    /// 사용자가 배울 언어를 직접 고른 적이 있는지
    static var hasChosenLearning: Bool { defaults.string(forKey: learningKey) != nil }
}

// MARK: - Localized dictionary

extension Dictionary where Key == String, Value == String {
    /// 언어 코드 → 문장 사전에서 화면 언어에 맞는 것을 고른다. (없으면 영어 → 한국어 → 아무거나)
    var localized: String {
        self[AppLanguage.uiCode]
            ?? self[AppLanguage.native.rawValue]
            ?? self[AppLanguage.english.rawValue]
            ?? self[AppLanguage.korean.rawValue]
            ?? values.first
            ?? ""
    }
}
