import Foundation

// MARK: - Content Translations

/// 한국어로만 쓰인 기본 콘텐츠(인도네시아어 시나리오·하루 코스·단어장)의 다른 화면 언어 번역.
/// `Content/translations.<언어>.json` 에 "키 → 번역" 으로 들어 있다. 키 규칙은 `ContentKey`.
enum ContentTranslations {
    private static let table: [String: String] = {
        guard AppLanguage.native != .korean else { return [:] }
        return load(AppLanguage.native.rawValue) ?? load(AppLanguage.english.rawValue) ?? [:]
    }()

    private static func load(_ code: String) -> [String: String]? {
        guard let url = Bundle.main.url(forResource: "translations.\(code)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict
    }

    /// 화면 언어가 한국어면 원문, 아니면 번역 (번역이 없으면 원문)
    static func text(_ key: String, korean: String) -> String {
        guard AppLanguage.native != .korean, !korean.isEmpty else { return korean }
        return table[key] ?? korean
    }
}

/// 번역 표의 키 규칙. 번역 원본을 뽑는 스크립트(scripts/export_content_strings.swift)와 같이 쓴다.
enum ContentKey {
    static func node(_ id: String) -> String { "node:\(id)" }
    static func scenarioTitle(_ title: String) -> String { "scenario:\(title)" }
    static func course(_ id: String, _ field: String) -> String { "course:\(id):\(field)" }
    static func stop(_ id: String, _ field: String) -> String { "stop:\(id):\(field)" }
    static func vocab(_ word: String, _ field: String) -> String { "vocab:\(word):\(field)" }
    static func example(_ sentence: String) -> String { "example:\(sentence)" }
    static func vocabCategory(_ name: String) -> String { "vocabcat:\(name)" }
    static func slang(_ word: String) -> String { "slang:\(word)" }
}

// MARK: - Situation Library (상황별 회화, 6개 언어 공통)

/// `Content/situations.<언어>.json` — 공항·숙소·식당 등 상황별 짧은 회화. 언어마다 53개.
enum SituationLibrary {
    struct Category: Identifiable, Hashable {
        let id: String
        let icon: String
        let names: [String: String]
        var name: String { names.localized }
    }

    private struct FileNode: Decodable {
        let id: String
        let speaker: String
        let text: String
        let meaning: [String: String]
        let children: [FileNode]
    }

    private struct FileScenario: Decodable {
        let id: String
        let category: String
        let emoji: String
        let title: [String: String]
        let description: [String: String]
        let root: FileNode
    }

    private struct File: Decodable {
        let language: String
        let scenarios: [FileScenario]
    }

    private struct FileCategory: Decodable {
        let icon: String
        let name: [String: String]
    }

    static let categoryOrder = ["basic", "casual", "restaurant", "transportation", "airport",
                                "hotel", "shopping", "tourism", "emergency"]

    static let categories: [Category] = {
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: FileCategory].self, from: data)
        else { return [] }
        return categoryOrder.compactMap { key in
            dict[key].map { Category(id: key, icon: $0.icon, names: $0.name) }
        }
    }()

    private static var cache: [AppLanguage: [ConversationScenario]] = [:]

    static func scenarios(for language: AppLanguage) -> [ConversationScenario] {
        if let cached = cache[language] { return cached }
        guard let url = Bundle.main.url(forResource: "situations.\(language.rawValue)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [] }

        let list = file.scenarios.map { s in
            ConversationScenario(
                id: stableUUID("situation-\(s.id)"),
                key: "situation-\(s.id)",
                language: language,
                title: s.title[language.rawValue] ?? s.title.localized,
                titleMeanings: s.title.filter { $0.key != language.rawValue },
                description: s.description.localized,
                emoji: s.emoji,
                root: node(s.root),
                difficulty: depth(s.root) > 3 ? .intermediate : .beginner,
                category: s.category
            )
        }
        cache[language] = list
        return list
    }

    private static func node(_ n: FileNode) -> ConversationNode {
        ConversationNode(
            id: n.id,
            speaker: n.speaker == "me" ? .me : .other,
            text: n.text,
            meanings: n.meaning,
            children: n.children.map(node)
        )
    }

    private static func depth(_ n: FileNode) -> Int {
        1 + (n.children.map(depth).max() ?? 0)
    }
}

// MARK: - Scenario Library

/// 배우는 언어에 맞는 기본 시나리오 묶음.
enum ScenarioLibrary {
    /// 공들여 만든 스몰토크 (지금은 인도네시아어만)
    static func smallTalk(for language: AppLanguage) -> [ConversationScenario] {
        language == .indonesian ? ConversationData.allScenarios : []
    }

    /// 하루 코스 (지금은 인도네시아어만)
    static func courses(for language: AppLanguage) -> [JourneyCourse] {
        language == .indonesian ? JourneyData.allCourses : []
    }

    static func situations(for language: AppLanguage) -> [ConversationScenario] {
        SituationLibrary.scenarios(for: language)
    }

    /// 지금 권한으로 열 수 있는 것만 (Pro 가 아니면 잠긴 상황별 회화를 뺀다)
    @MainActor
    static func available(for language: AppLanguage) -> [ConversationScenario] {
        all(for: language).filter { !MalmunPro.shared.isLocked($0) }
    }

    /// 이 언어로 연습할 수 있는 기본 시나리오 전부 (스몰토크 → 하루 코스 → 상황별)
    static func all(for language: AppLanguage) -> [ConversationScenario] {
        smallTalk(for: language)
            + courses(for: language).flatMap { $0.stops.map(\.scenario) }
            + situations(for: language)
    }
}

/// 문자열에서 늘 같은 UUID 를 만든다. (기록·사용자 답변이 앱을 다시 켜도 같은 시나리오에 붙도록)
func stableUUID(_ seed: String) -> UUID {
    // FNV-1a 64bit 두 번으로 128bit 를 채운다.
    func fnv(_ s: String, _ basis: UInt64) -> UInt64 {
        var h = basis
        for b in s.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return h
    }
    let a = fnv(seed, 0xcbf29ce484222325)
    let b = fnv(seed, 0x84222325cbf29ce4)
    var bytes = [UInt8](repeating: 0, count: 16)
    for i in 0..<8 { bytes[i] = UInt8((a >> (8 * UInt64(i))) & 0xff); bytes[8 + i] = UInt8((b >> (8 * UInt64(i))) & 0xff) }
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    let u = (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
             bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
    return UUID(uuid: u)
}
