import Foundation

@MainActor
final class AIScenarioStore: ObservableObject {
    @Published private(set) var scenarios: [AIScenario] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ai_scenarios.json")
    }()

    init() { load() }

    func add(_ s: AIScenario) {
        scenarios.insert(s, at: 0)
        save()
    }

    func delete(id: UUID) {
        scenarios.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([AIScenario].self, from: data) {
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
