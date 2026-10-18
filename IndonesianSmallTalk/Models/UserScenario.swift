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
    /// 만든 언어 (AppLanguage.rawValue). 예전 저장분은 nil = 인도네시아어
    var languageCode: String? = AppLanguage.learning.rawValue

    var language: AppLanguage { languageCode.flatMap(AppLanguage.init(rawValue:)) ?? .indonesian }

    var rootNodeId: String { "scenario-\(id.uuidString)-root" }

    func toScenario() -> ConversationScenario {
        let root = ConversationNode(
            id: rootNodeId,
            speaker: openerSpeakerIsOther ? .other : .me,
            userText: openingIndonesian,
            userMeaning: openingKorean,
            romanization: openingRomanization,
            polarity: .neutral,
            coachTip: nil,
            children: []
        )
        let difficulty = ConversationScenario.Difficulty(rawValue: difficultyRaw) ?? .beginner
        return ConversationScenario(
            id: id,
            language: language,
            title: title,
            userTitleMeaning: titleKo,
            description: description,
            emoji: emoji,
            root: root,
            difficulty: difficulty
        )
    }
}

@MainActor
final class UserScenarioStore: ObservableObject {
    @Published private(set) var allScenarios: [UserScenario] = []

    /// 지금 배우는 언어로 만든 것만
    var scenarios: [UserScenario] { allScenarios.filter { $0.language == AppLanguage.learning } }

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("userscenarios.json")
    }()

    init() {
        load()
    }

    func add(_ s: UserScenario) {
        allScenarios.insert(s, at: 0)
        save()
    }

    func update(_ s: UserScenario) {
        guard let idx = allScenarios.firstIndex(where: { $0.id == s.id }) else { return }
        allScenarios[idx] = s
        save()
    }

    func delete(id: UUID) {
        allScenarios.removeAll { $0.id == id }
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
            allScenarios = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(allScenarios) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
