import Foundation

struct UserReply: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var parentNodeId: String
    var indonesian: String
    var korean: String
    var romanization: String
    var polarity: Polarity = .neutral
    var speakerRaw: String = "me"
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        parentNodeId: String,
        indonesian: String,
        korean: String,
        romanization: String = "",
        polarity: Polarity = .neutral,
        speakerRaw: String = "me",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.parentNodeId = parentNodeId
        self.indonesian = indonesian
        self.korean = korean
        self.romanization = romanization
        self.polarity = polarity
        self.speakerRaw = speakerRaw
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, parentNodeId, indonesian, korean, romanization, polarity, speakerRaw, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        parentNodeId = try c.decode(String.self, forKey: .parentNodeId)
        indonesian = try c.decode(String.self, forKey: .indonesian)
        korean = try c.decode(String.self, forKey: .korean)
        romanization = try c.decode(String.self, forKey: .romanization)
        polarity = (try? c.decode(Polarity.self, forKey: .polarity)) ?? .neutral
        speakerRaw = (try? c.decode(String.self, forKey: .speakerRaw)) ?? "me"
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    /// 정적 트리에 끼워 넣을 수 있도록 ConversationNode 로 변환.
    /// id 는 "user-<UUID>" 접두어로 사용자 추가 응답임을 표시.
    func toNode() -> ConversationNode {
        ConversationNode(
            id: "user-\(id.uuidString)",
            speaker: speakerRaw == "other" ? .other : .me,
            indonesian: indonesian,
            korean: korean,
            romanization: romanization,
            polarity: polarity,
            coachTip: nil,
            children: []
        )
    }
}

extension ConversationNode {
    var isUserAdded: Bool { id.hasPrefix("user-") }
    var userReplyId: UUID? {
        guard isUserAdded else { return nil }
        return UUID(uuidString: String(id.dropFirst("user-".count)))
    }
}

@MainActor
final class UserReplyStore: ObservableObject {
    @Published private(set) var replies: [UserReply] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("userreplies.json")
    }()

    init() {
        load()
    }

    func add(_ reply: UserReply) {
        replies.append(reply)
        save()
    }

    func delete(id: UUID) {
        replies.removeAll { $0.id == id }
        save()
    }

    func update(_ reply: UserReply) {
        if let idx = replies.firstIndex(where: { $0.id == reply.id }) {
            replies[idx] = reply
            save()
        }
    }

    func replies(for parentNodeId: String) -> [UserReply] {
        replies
            .filter { $0.parentNodeId == parentNodeId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([UserReply].self, from: data) {
            replies = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(replies) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
