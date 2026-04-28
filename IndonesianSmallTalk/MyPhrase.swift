import Foundation

struct MyPhrase: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var indonesian: String
    var korean: String
    var context: String
    var polarity: Polarity = .neutral
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        indonesian: String,
        korean: String,
        context: String = "",
        polarity: Polarity = .neutral,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.indonesian = indonesian
        self.korean = korean
        self.context = context
        self.polarity = polarity
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, indonesian, korean, context, polarity, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        indonesian = try c.decode(String.self, forKey: .indonesian)
        korean = try c.decode(String.self, forKey: .korean)
        context = try c.decode(String.self, forKey: .context)
        polarity = (try? c.decode(Polarity.self, forKey: .polarity)) ?? .neutral
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

@MainActor
final class PhraseStore: ObservableObject {
    @Published private(set) var phrases: [MyPhrase] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("myphrases.json")
    }()

    init() {
        load()
    }

    func add(_ phrase: MyPhrase) {
        phrases.insert(phrase, at: 0)
        save()
    }

    func update(_ phrase: MyPhrase) {
        guard let idx = phrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        phrases[idx] = phrase
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where index < phrases.count {
            phrases.remove(at: index)
        }
        save()
    }

    func delete(id: UUID) {
        phrases.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([MyPhrase].self, from: data) {
            phrases = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(phrases) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
