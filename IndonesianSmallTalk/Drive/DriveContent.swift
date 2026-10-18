import Foundation

// MARK: - Drive Line / Lesson

/// 퇴근길 모드에서 한 번에 읽어 주는 한 줄.
struct DriveLine: Hashable {
    enum Role { case listen, speak }   // listen = 상대 말 듣기, speak = 내가 말해 보기
    let role: Role
    let text: String       // 배우는 언어
    let meaning: String    // 화면 언어
}

/// 한 장면(시나리오 하나, 표현 묶음 하나). 장면이 바뀔 때 제목을 읽어 준다.
struct DriveLesson: Identifiable, Hashable {
    let id: String
    let title: String      // 화면 언어 제목 (읽어 주는 용)
    let lines: [DriveLine]
}

// MARK: - Source

/// 무엇을 들을지
enum DriveSource: String, CaseIterable, Identifiable {
    case mix            // 섞어서 (기본)
    case conversations  // 스몰토크·하루 코스
    case situations     // 상황별 회화
    case phrases        // 내 표현
    case words          // 단어장

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mix: return String(localized: "골고루 섞어서")
        case .conversations: return String(localized: "스몰토크 대화")
        case .situations: return String(localized: "상황별 회화")
        case .phrases: return String(localized: "내 표현")
        case .words: return String(localized: "단어장")
        }
    }

    var icon: String {
        switch self {
        case .mix: return "shuffle"
        case .conversations: return "bubble.left.and.bubble.right.fill"
        case .situations: return "map.fill"
        case .phrases: return "text.book.closed.fill"
        case .words: return "character.book.closed.fill"
        }
    }
}

// MARK: - Builder

/// 배우는 언어의 콘텐츠를 퇴근길용 장면 목록으로 만든다.
/// 저장소(내 표현·단어장)는 파일에서 바로 읽어서, 화면 없이(Siri·CarPlay) 시작해도 된다.
@MainActor
enum DriveContent {
    static let phraseChunk = 6
    static let wordChunk = 6

    /// 내 표현·단어장 읽는 곳. 앱이 뜨면 화면이 쓰는 저장소로 바꿔 끼운다(IndonesianSmallTalkApp).
    /// 화면 없이(Siri·CarPlay) 시작하면 파일에서 한 번 읽은 저장소를 쓴다.
    static var phrases: () -> [MyPhrase] = { fallbackPhrases.phrases }
    static var words: () -> [VocabWord] = { fallbackWords.words }
    private static let fallbackPhrases = PhraseStore()
    private static let fallbackWords = VocabularyStore()

    static func lessons(for source: DriveSource, language: AppLanguage = .learning) -> [DriveLesson] {
        switch source {
        case .conversations:
            let talk = ScenarioLibrary.smallTalk(for: language)
                + ScenarioLibrary.courses(for: language).flatMap { $0.stops.map(\.scenario) }
            return talk.map(lesson(from:))
        case .situations:
            return ScenarioLibrary.situations(for: language).map(lesson(from:))
        case .phrases:
            return phraseLessons()
        case .words:
            return wordLessons()
        case .mix:
            return mixed(language: language)
        }
    }

    /// 대화 하나 → 장면 하나. 갈림길에서는 긍정적인 답을 따라간다.
    static func lesson(from scenario: ConversationScenario) -> DriveLesson {
        var lines: [DriveLine] = []
        var node: ConversationNode? = scenario.root
        while let n = node {
            lines.append(DriveLine(role: n.speaker == .me ? .speak : .listen, text: n.text, meaning: n.meaning))
            node = n.children.first { $0.polarity == .positive } ?? n.children.first
        }
        return DriveLesson(id: scenario.key, title: scenario.titleKo, lines: lines)
    }

    private static func phraseLessons() -> [DriveLesson] {
        let phrases = phrases()
        return stride(from: 0, to: phrases.count, by: phraseChunk).map { start in
            let chunk = phrases[start..<min(start + phraseChunk, phrases.count)]
            return DriveLesson(
                id: "phrases-\(start)",
                title: String(localized: "내 표현"),
                lines: chunk.map { DriveLine(role: .speak, text: $0.text, meaning: $0.meaning) }
            )
        }
    }

    private static func wordLessons() -> [DriveLesson] {
        // 아직 못 외운 단어부터
        let words = words().sorted { !$0.isLearned && $1.isLearned }
        return stride(from: 0, to: words.count, by: wordChunk).map { start in
            let chunk = words[start..<min(start + wordChunk, words.count)]
            let lines = chunk.flatMap { w -> [DriveLine] in
                var l = [DriveLine(role: .speak, text: w.text, meaning: w.meaning)]
                if let ex = w.examples.first {
                    l.append(DriveLine(role: .speak, text: ex.indonesian, meaning: ex.korean))
                }
                return l
            }
            return DriveLesson(id: "words-\(start)", title: String(localized: "단어장"), lines: lines)
        }
    }

    /// 대화 1 → 상황 1 → 내 표현 1묶음 → 단어 1묶음 … 차례로. 빈 쪽은 건너뛴다.
    private static func mixed(language: AppLanguage) -> [DriveLesson] {
        let groups = [lessons(for: .conversations, language: language),
                      lessons(for: .situations, language: language),
                      lessons(for: .phrases, language: language),
                      lessons(for: .words, language: language)].filter { !$0.isEmpty }
        guard let longest = groups.map(\.count).max() else { return [] }
        var out: [DriveLesson] = []
        for i in 0..<longest {
            for g in groups where i < g.count { out.append(g[i]) }
        }
        return out
    }
}

// MARK: - Settings

/// 퇴근길 모드 설정. 화면(@AppStorage)과 엔진이 같은 키를 쓴다.
enum DriveSettings {
    static let rateKey = "drive.rate"
    static let gapKey = "drive.gap"
    static let repeatKey = "drive.repeatTwice"
    static let sourceKey = "drive.source"
    static let voiceKey = "drive.voice"
    static let guideSeenKey = "drive.guideSeen"

    /// 말하기 속도 (기본 속도의 배수)
    static var rate: Double { UserDefaults.standard.object(forKey: rateKey) as? Double ?? 0.9 }
    /// 내가 말해 볼 시간 배수 (1 = 보통)
    static var gap: Double { UserDefaults.standard.object(forKey: gapKey) as? Double ?? 1.0 }
    /// 정답을 한 번 더 들려줄지
    static var repeatTwice: Bool { UserDefaults.standard.object(forKey: repeatKey) as? Bool ?? true }
    /// 목소리로 조작 (말해 볼 차례에 마이크로 듣기)
    static var voice: Bool { UserDefaults.standard.object(forKey: voiceKey) as? Bool ?? true }
    static var source: DriveSource {
        DriveSource(rawValue: UserDefaults.standard.string(forKey: sourceKey) ?? "") ?? .mix
    }

    /// 이어 듣기 위치 (언어·소스별)
    static func cursorKey(_ source: DriveSource, _ language: AppLanguage) -> String {
        "drive.cursor.\(language.rawValue).\(source.rawValue)"
    }
}
