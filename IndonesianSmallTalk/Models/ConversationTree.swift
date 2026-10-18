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
    let text: String                  // 배우는 언어 문장
    let meanings: [String: String]    // 언어 코드 → 뜻
    let romanization: String          // 한글 발음 (한국어 화면에서만 보여 준다)
    let polarity: Polarity
    let coachTip: CoachTip?
    let children: [ConversationNode]

    /// 화면 언어로 된 뜻
    var meaning: String { meanings.localized }

    /// 한국어 화면일 때만 한글 발음
    var displayRomanization: String { AppLanguage.showsHangulRomanization ? romanization : "" }

    enum Speaker {
        case me, other
        var labelKo: String { self == .me ? String(localized: "나") : String(localized: "상대방") }
    }

    init(
        id: String,
        speaker: Speaker,
        text: String,
        meanings: [String: String],
        romanization: String = "",
        polarity: Polarity = .neutral,
        coachTip: CoachTip? = nil,
        children: [ConversationNode] = []
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.meanings = meanings
        self.romanization = romanization
        self.polarity = polarity
        self.coachTip = coachTip
        self.children = children
    }

    /// 인도네시아어 기본 콘텐츠용: 한국어 뜻 + 다른 화면 언어 번역표(ContentTranslations)
    convenience init(
        id: String,
        speaker: Speaker,
        indonesian: String,
        korean: String,
        romanization: String = "",
        polarity: Polarity = .neutral,
        coachTip: CoachTip? = nil,
        children: [ConversationNode] = []
    ) {
        var meanings = [AppLanguage.korean.rawValue: korean]
        let translated = ContentTranslations.text(ContentKey.node(id), korean: korean)
        if AppLanguage.native != .korean, translated != korean { meanings[AppLanguage.native.rawValue] = translated }
        self.init(id: id, speaker: speaker, text: indonesian, meanings: meanings,
                  romanization: romanization, polarity: polarity, coachTip: coachTip, children: children)
    }

    /// 사용자가 직접 쓴 문장: 뜻은 쓴 사람의 화면 언어로 저장된 것 하나
    convenience init(
        id: String,
        speaker: Speaker,
        userText: String,
        userMeaning: String,
        romanization: String = "",
        polarity: Polarity = .neutral,
        coachTip: CoachTip? = nil,
        children: [ConversationNode] = []
    ) {
        self.init(id: id, speaker: speaker, text: userText,
                  meanings: [AppLanguage.native.rawValue: userMeaning],
                  romanization: romanization, polarity: polarity, coachTip: coachTip, children: children)
    }
}

// MARK: - Conversation Scenario

struct ConversationScenario: Identifiable {
    let id: UUID
    /// 기록·진행률에 쓰는 고정 키
    let key: String
    let language: AppLanguage
    let title: String                    // 배우는 언어 제목
    let titleMeanings: [String: String]  // 언어 코드 → 제목 뜻
    let description: String
    let emoji: String
    let root: ConversationNode
    let difficulty: Difficulty
    /// 상황별 회화의 분류 (SituationLibrary.categories). 스몰토크·사용자 시나리오는 nil
    let category: String?

    /// 화면 언어로 된 제목
    var titleKo: String { titleMeanings.localized }

    init(
        id: UUID = UUID(),
        key: String? = nil,
        language: AppLanguage = .indonesian,
        title: String,
        titleMeanings: [String: String],
        description: String,
        emoji: String,
        root: ConversationNode,
        difficulty: Difficulty,
        category: String? = nil
    ) {
        self.id = id
        self.key = key ?? id.uuidString
        self.language = language
        self.title = title
        self.titleMeanings = titleMeanings
        self.description = description
        self.emoji = emoji
        self.root = root
        self.difficulty = difficulty
        self.category = category
    }

    /// 인도네시아어 기본 콘텐츠용 (한국어 제목 + 번역표)
    init(
        id: UUID = UUID(),
        key: String? = nil,
        title: String,
        titleKo: String,
        description: String,
        emoji: String,
        root: ConversationNode,
        difficulty: Difficulty
    ) {
        var meanings = [AppLanguage.korean.rawValue: titleKo]
        let translated = ContentTranslations.text(ContentKey.scenarioTitle(title), korean: titleKo)
        if AppLanguage.native != .korean, translated != titleKo { meanings[AppLanguage.native.rawValue] = translated }
        self.init(id: id, key: key, language: .indonesian, title: title, titleMeanings: meanings,
                  description: description, emoji: emoji, root: root, difficulty: difficulty)
    }

    /// 사용자가 만든 시나리오 (제목 뜻은 쓴 사람의 화면 언어)
    init(
        id: UUID,
        language: AppLanguage,
        title: String,
        userTitleMeaning: String,
        description: String,
        emoji: String,
        root: ConversationNode,
        difficulty: Difficulty
    ) {
        self.init(id: id, language: language, title: title,
                  titleMeanings: [AppLanguage.native.rawValue: userTitleMeaning],
                  description: description, emoji: emoji, root: root, difficulty: difficulty)
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
            case .beginner: return String(localized: "초급")
            case .intermediate: return String(localized: "중급")
            case .advanced: return String(localized: "고급")
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

    func setOpener(_ node: ConversationNode) {
        currentPath = [node]
        selectedNode = nil
        score = 0
        totalChoices = 0
        positiveChoices = 0
        showResult = false
    }

    /// pre-opener만 path에 넣음. 이후 allOpeners가 응답 선택지로 제공됨
    func setPreOpener(_ preNode: ConversationNode) {
        currentPath = [preNode]
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
