import Foundation

/// 회화 뼈대 레퍼런스 기반 격식 층위.
/// F=Formal(격식), N=Neutral(중립, 안전한 기본값), C=Casual(캐주얼), S=Slang(슬랭, 듣기만)
enum FormalityLevel: String, Codable, CaseIterable {
    case formal  = "F"
    case neutral = "N"
    case casual  = "C"
    case slang   = "S"

    var label: String {
        switch self {
        case .formal:  return "격식"
        case .neutral: return "중립"
        case .casual:  return "캐주얼"
        case .slang:   return "슬랭"
        }
    }
}

struct VocabExample: Codable, Hashable {
    var indonesian: String
    var korean: String
    var level: FormalityLevel? = nil

    init(_ indonesian: String, _ korean: String, level: FormalityLevel? = nil) {
        self.indonesian = indonesian
        self.korean = korean
        self.level = level
    }

    enum CodingKeys: String, CodingKey {
        case indonesian, korean, level
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        indonesian = try c.decode(String.self, forKey: .indonesian)
        korean     = try c.decode(String.self, forKey: .korean)
        level      = try? c.decode(FormalityLevel.self, forKey: .level)
    }
}

struct VocabWord: Identifiable, Codable {
    var id: UUID = UUID()
    var indonesian: String
    var korean: String
    var romanization: String = ""
    var category: String = "기타"
    var notes: String = ""
    var examples: [VocabExample] = []
    var tier: Int = 2
    var studyCount: Int = 0
    var isLearned: Bool = false
    var createdAt: Date = Date()

    /// 출장 100단어 토픽 카테고리. 사용자 추가 단어용 "기타" 포함.
    static let categories = [
        "인사·호칭",
        "긍정·부정·확인",
        "부탁·사과·감사",
        "의문사",
        "동사·조동사",
        "숫자·가격",
        "식당·음식",
        "교통",
        "장소·방향",
        "시간",
        "호텔·비즈니스",
        "정도·상태",
        "추임새·접속사",
        "기타"
    ]

    init(
        id: UUID = UUID(),
        indonesian: String,
        korean: String,
        romanization: String = "",
        category: String = "기타",
        notes: String = "",
        examples: [VocabExample] = [],
        tier: Int = 2,
        studyCount: Int = 0,
        isLearned: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.indonesian = indonesian
        self.korean = korean
        self.romanization = romanization
        self.category = category
        self.notes = notes
        self.examples = examples
        self.tier = tier
        self.studyCount = studyCount
        self.isLearned = isLearned
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, indonesian, korean, romanization, category, notes, examples, tier, studyCount, isLearned, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self, forKey: .id)
        indonesian    = try c.decode(String.self, forKey: .indonesian)
        korean        = try c.decode(String.self, forKey: .korean)
        romanization  = (try? c.decode(String.self, forKey: .romanization)) ?? ""
        category      = (try? c.decode(String.self, forKey: .category)) ?? "기타"
        notes         = (try? c.decode(String.self, forKey: .notes)) ?? ""
        examples      = (try? c.decode([VocabExample].self, forKey: .examples)) ?? []
        tier          = (try? c.decode(Int.self, forKey: .tier)) ?? 2
        studyCount    = (try? c.decode(Int.self, forKey: .studyCount)) ?? 0
        isLearned     = (try? c.decode(Bool.self, forKey: .isLearned)) ?? false
        createdAt     = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
    }
}

@MainActor
final class VocabularyStore: ObservableObject {
    @Published private(set) var words: [VocabWord] = []

    /// 내장 단어 시드 버전. 이 숫자가 올라가면 다음 실행 때 새 단어를 머지함.
    private static let currentBuiltInVersion = 2
    private static let builtInVersionKey = "vocabularyBuiltInVersion"

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("vocabulary.json")
    }()

    init() {
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        load()
        if !exists {
            // 첫 실행 — 시드 채우기
            words = BuiltInVocabulary.seedItems
            save()
        } else {
            // 기존 유저 — 새 내장 단어가 있으면 머지 (덮어쓰지 않음)
            let storedVersion = UserDefaults.standard.integer(forKey: Self.builtInVersionKey)
            if storedVersion < Self.currentBuiltInVersion {
                mergeNewBuiltIns()
            }
        }
        UserDefaults.standard.set(Self.currentBuiltInVersion, forKey: Self.builtInVersionKey)
    }

    /// 내장 시드 중 사용자 데이터에 없는 단어만 추가. 기존 단어는 그대로 유지.
    private func mergeNewBuiltIns() {
        let existing = Set(words.map { $0.indonesian })
        let toAdd = BuiltInVocabulary.seedItems.filter { !existing.contains($0.indonesian) }
        guard !toAdd.isEmpty else { return }
        words.append(contentsOf: toAdd)
        save()
    }

    /// 내장 단어를 강제로 다시 채워넣음. 사용자가 추가/수정/삭제한 단어는 모두 사라짐.
    func resetToBuiltIn() {
        words = BuiltInVocabulary.seedItems
        save()
        UserDefaults.standard.set(Self.currentBuiltInVersion, forKey: Self.builtInVersionKey)
    }

    func words(in category: String) -> [VocabWord] {
        words.filter { $0.category == category }
    }

    func words(tier: Int) -> [VocabWord] {
        words.filter { $0.tier == tier }
    }

    func add(_ word: VocabWord) {
        words.insert(word, at: 0)
        save()
    }

    func update(_ word: VocabWord) {
        guard let idx = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[idx] = word
        save()
    }

    func delete(id: UUID) {
        words.removeAll { $0.id == id }
        save()
    }

    func toggleLearned(id: UUID) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        words[idx].isLearned.toggle()
        save()
    }

    func incrementStudy(id: UUID) {
        guard let idx = words.firstIndex(where: { $0.id == id }) else { return }
        words[idx].studyCount += 1
        save()
    }

    var unlearnedWords: [VocabWord] { words.filter { !$0.isLearned } }
    var learnedWords: [VocabWord] { words.filter { $0.isLearned } }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([VocabWord].self, from: data) {
            words = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(words) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
