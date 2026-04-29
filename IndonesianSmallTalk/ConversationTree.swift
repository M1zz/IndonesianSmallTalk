import Foundation

// Polarity 는 Polarity.swift 로 분리됨 (키보드 익스텐션과 공유)

// MARK: - Coach Tip

struct CoachTip {
    let label: String       // technique name
    let tip: String         // explanation
    let why: String         // reason
}

// MARK: - Conversation Node

class ConversationNode: Identifiable, ObservableObject {
    let id: String
    let speaker: Speaker
    let indonesian: String   // Bahasa Indonesia
    let korean: String       // Korean translation
    let romanization: String // pronunciation guide
    let polarity: Polarity
    let coachTip: CoachTip?
    let children: [ConversationNode]

    enum Speaker {
        case me, other
        var label: String { self == .me ? "Kamu" : "Orang lain" }
        var labelKo: String { self == .me ? "나" : "상대방" }
    }

    init(
        id: String,
        speaker: Speaker,
        indonesian: String,
        korean: String,
        romanization: String = "",
        polarity: Polarity = .neutral,
        coachTip: CoachTip? = nil,
        children: [ConversationNode] = []
    ) {
        self.id = id
        self.speaker = speaker
        self.indonesian = indonesian
        self.korean = korean
        self.romanization = romanization
        self.polarity = polarity
        self.coachTip = coachTip
        self.children = children
    }
}

// MARK: - Conversation Scenario

struct ConversationScenario: Identifiable {
    let id: UUID
    let title: String
    let titleKo: String
    let description: String
    let emoji: String
    let root: ConversationNode
    let difficulty: Difficulty

    init(
        id: UUID = UUID(),
        title: String,
        titleKo: String,
        description: String,
        emoji: String,
        root: ConversationNode,
        difficulty: Difficulty
    ) {
        self.id = id
        self.title = title
        self.titleKo = titleKo
        self.description = description
        self.emoji = emoji
        self.root = root
        self.difficulty = difficulty
    }

    enum Difficulty: String {
        case beginner = "Pemula"
        case intermediate = "Menengah"
        case advanced = "Mahir"
        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
        var labelKo: String {
            switch self {
            case .beginner: return "초급"
            case .intermediate: return "중급"
            case .advanced: return "고급"
            }
        }
    }
}

// MARK: - Practice Session

class PracticeSession: ObservableObject {
    @Published var currentPath: [ConversationNode] = []
    @Published var selectedNode: ConversationNode?
    @Published var score: Int = 0
    @Published var totalChoices: Int = 0
    @Published var positiveChoices: Int = 0
    @Published var showResult: Bool = false

    let scenario: ConversationScenario

    init(scenario: ConversationScenario) {
        self.scenario = scenario
        self.currentPath = [scenario.root]
    }

    var currentNode: ConversationNode? { currentPath.last }

    var availableChoices: [ConversationNode] {
        currentPath.last?.children ?? []
    }

    var isFinished: Bool {
        availableChoices.isEmpty
    }

    func choose(_ node: ConversationNode) {
        currentPath.append(node)
        selectedNode = node
        totalChoices += 1
        if node.polarity == .positive { positiveChoices += 1 }
        score += node.polarity == .positive ? 10 : 5
    }

    func reset() {
        currentPath = [scenario.root]
        selectedNode = nil
        score = 0
        totalChoices = 0
        positiveChoices = 0
        showResult = false
    }

    var progressRatio: Double {
        guard !scenario.root.children.isEmpty else { return 0 }
        return Double(currentPath.count - 1) / Double(maxDepth(scenario.root))
    }

    private func maxDepth(_ node: ConversationNode) -> Int {
        if node.children.isEmpty { return 0 }
        return 1 + (node.children.map { maxDepth($0) }.max() ?? 0)
    }

    var feedbackMessage: String {
        let ratio = totalChoices == 0 ? 0.0 : Double(positiveChoices) / Double(totalChoices)
        if ratio >= 0.7 { return "Luar biasa! 🎉 Percakapan yang sangat baik!" }
        if ratio >= 0.4 { return "Bagus! 👍 Terus berlatih ya!" }
        return "Coba lagi! 💪 Pilih respons yang lebih positif." }

    var feedbackKo: String {
        let ratio = totalChoices == 0 ? 0.0 : Double(positiveChoices) / Double(totalChoices)
        if ratio >= 0.7 { return "훌륭해요! 매우 자연스러운 대화예요!" }
        if ratio >= 0.4 { return "좋아요! 계속 연습해봐요!" }
        return "다시 해봐요! 좀 더 긍정적인 응답을 골라보세요." }
}
