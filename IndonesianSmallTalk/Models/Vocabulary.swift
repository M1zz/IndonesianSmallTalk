import Foundation

struct VocabWord: Identifiable, Codable {
    var id: UUID = UUID()
    var indonesian: String
    var korean: String
    var romanization: String = ""
    var category: String = "기타"
    var notes: String = ""
    var studyCount: Int = 0
    var isLearned: Bool = false
    var createdAt: Date = Date()

    static let categories = ["명사", "동사", "형용사", "부사", "숙어", "기타"]

    init(
        id: UUID = UUID(),
        indonesian: String,
        korean: String,
        romanization: String = "",
        category: String = "기타",
        notes: String = "",
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
        self.studyCount = studyCount
        self.isLearned = isLearned
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, indonesian, korean, romanization, category, notes, studyCount, isLearned, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self, forKey: .id)
        indonesian    = try c.decode(String.self, forKey: .indonesian)
        korean        = try c.decode(String.self, forKey: .korean)
        romanization  = (try? c.decode(String.self, forKey: .romanization)) ?? ""
        category      = (try? c.decode(String.self, forKey: .category)) ?? "기타"
        notes         = (try? c.decode(String.self, forKey: .notes)) ?? ""
        studyCount    = (try? c.decode(Int.self, forKey: .studyCount)) ?? 0
        isLearned     = (try? c.decode(Bool.self, forKey: .isLearned)) ?? false
        createdAt     = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
    }
}

@MainActor
final class VocabularyStore: ObservableObject {
    @Published private(set) var words: [VocabWord] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("vocabulary.json")
    }()

    init() { load() }

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
