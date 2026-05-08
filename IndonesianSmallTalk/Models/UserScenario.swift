import Foundation

struct UserScenario: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String           // Bahasa Indonesia
    var titleKo: String         // 한국어
    var description: String
    var emoji: String
    var difficultyRaw: String   // ConversationScenario.Difficulty.rawValue
    var openerSpeakerIsOther: Bool   // true면 상대방이 먼저 말 (대부분 이 경우)
    var openingIndonesian: String
    var openingKorean: String
    var openingRomanization: String
    var createdAt: Date = Date()

    var rootNodeId: String { "scenario-\(id.uuidString)-root" }

    func toScenario() -> ConversationScenario {
        let root = ConversationNode(
            id: rootNodeId,
            speaker: openerSpeakerIsOther ? .other : .me,
            indonesian: openingIndonesian,
            korean: openingKorean,
            romanization: openingRomanization,
            polarity: .neutral,
            coachTip: nil,
            children: []
        )
        let difficulty = ConversationScenario.Difficulty(rawValue: difficultyRaw) ?? .beginner
        return ConversationScenario(
            id: id,
            title: title,
            titleKo: titleKo,
            description: description,
            emoji: emoji,
            root: root,
            difficulty: difficulty
        )
    }
}

@MainActor
final class UserScenarioStore: ObservableObject {
    @Published private(set) var scenarios: [UserScenario] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("userscenarios.json")
    }()

    init() {
        load()
    }

    func add(_ s: UserScenario) {
        scenarios.insert(s, at: 0)
        save()
    }

    func delete(id: UUID) {
        scenarios.removeAll { $0.id == id }
        save()
    }

    var asScenarios: [ConversationScenario] {
        scenarios.map { $0.toScenario() }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([UserScenario].self, from: data) {
            scenarios = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(scenarios) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
