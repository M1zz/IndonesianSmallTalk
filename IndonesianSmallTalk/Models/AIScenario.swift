import Foundation

// MARK: - Codable conversation node (AI-generated, full tree)

struct ConversationNodeData: Codable, Identifiable {
    let id: String
    let speakerIsMe: Bool
    let indonesian: String
    let korean: String
    let romanization: String
    let polarity: String          // "positive" | "negative" | "neutral"
    let coachTipLabel: String?
    let coachTipText: String?
    let coachTipWhy: String?
    let children: [ConversationNodeData]

    func toConversationNode() -> ConversationNode {
        let pol: Polarity
        switch polarity {
        case "positive": pol = .positive
        case "negative": pol = .negative
        default:         pol = .neutral
        }
        let tip: CoachTip? = coachTipLabel.map {
            CoachTip(label: $0, tip: coachTipText ?? "", why: coachTipWhy ?? "")
        }
        return ConversationNode(
            id: id,
            speaker: speakerIsMe ? .me : .other,
            indonesian: indonesian,
            korean: korean,
            romanization: romanization,
            polarity: pol,
            coachTip: tip,
            children: children.map { $0.toConversationNode() }
        )
    }
}

// MARK: - Vocabulary item

struct VocabItem: Codable, Identifiable {
    var id: UUID = UUID()
    let indonesian: String
    let romanization: String      // 한글 발음
    let korean: String
    let category: String          // 동사 / 명사 / 형용사 / 부사 / 숙어

    enum CodingKeys: String, CodingKey {
        case id, indonesian, romanization, korean, category
    }

    init(id: UUID = UUID(), indonesian: String, romanization: String, korean: String, category: String) {
        self.id = id
        self.indonesian = indonesian
        self.romanization = romanization
        self.korean = korean
        self.category = category
    }
}

// MARK: - Grammar point

struct GrammarExample: Codable {
    let indonesian: String
    let korean: String
}

struct GrammarPoint: Codable, Identifiable {
    var id: UUID = UUID()
    let number: Int
    let titleId: String           // Indonesian pattern title
    let titleKo: String           // Korean explanation title
    let explanation: String
    let examples: [GrammarExample]

    enum CodingKeys: String, CodingKey {
        case id, number, titleId, titleKo, explanation, examples
    }

    init(id: UUID = UUID(), number: Int, titleId: String, titleKo: String, explanation: String, examples: [GrammarExample]) {
        self.id = id
        self.number = number
        self.titleId = titleId
        self.titleKo = titleKo
        self.explanation = explanation
        self.examples = examples
    }
}

// MARK: - Full AI-generated scenario package

struct AIScenario: Identifiable, Codable {
    let id: UUID
    let title: String             // Bahasa Indonesia
    let titleKo: String           // 한국어
    let description: String
    let emoji: String
    let difficultyRaw: String
    let rootNode: ConversationNodeData
    let vocabulary: [VocabItem]
    let grammarPoints: [GrammarPoint]
    let createdAt: Date
    let userPrompt: String        // what the user typed

    init(
        id: UUID = UUID(),
        title: String,
        titleKo: String,
        description: String,
        emoji: String,
        difficultyRaw: String,
        rootNode: ConversationNodeData,
        vocabulary: [VocabItem],
        grammarPoints: [GrammarPoint],
        createdAt: Date = Date(),
        userPrompt: String
    ) {
        self.id = id
        self.title = title
        self.titleKo = titleKo
        self.description = description
        self.emoji = emoji
        self.difficultyRaw = difficultyRaw
        self.rootNode = rootNode
        self.vocabulary = vocabulary
        self.grammarPoints = grammarPoints
        self.createdAt = createdAt
        self.userPrompt = userPrompt
    }

    func toScenario() -> ConversationScenario {
        ConversationScenario(
            id: id,
            title: title,
            titleKo: titleKo,
            description: description,
            emoji: emoji,
            root: rootNode.toConversationNode(),
            difficulty: ConversationScenario.Difficulty(rawValue: difficultyRaw) ?? .beginner
        )
    }

    var nodeCount: Int { countNodes(rootNode) }
    private func countNodes(_ n: ConversationNodeData) -> Int {
        1 + n.children.reduce(0) { $0 + countNodes($1) }
    }
}
