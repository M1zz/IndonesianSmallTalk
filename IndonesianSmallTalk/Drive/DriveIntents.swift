import AppIntents
import CoreSpotlight
import Foundation

// MARK: - Siri · 단축어

/// "말문 퇴근길 연습 시작" — 앱을 열지 않고 바로 소리로 시작한다.
/// 단축어 앱 ▸ 자동화 ▸ 'CarPlay에 연결될 때' 에 이 동작을 걸면 차에 타자마자 시작된다.
struct StartDriveIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "퇴근길 연습 시작"
    static var description = IntentDescription("배우는 언어로 퇴근길 듣기 연습을 이어서 시작해요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = DriveSession.shared
        if session.isActive { session.play() } else { session.start() }
        return .result()
    }
}

struct PauseDriveIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "퇴근길 연습 멈추기"
    static var description = IntentDescription("퇴근길 듣기 연습을 잠시 멈춰요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        DriveSession.shared.pause()
        return .result()
    }
}

/// "말문 계속" — 멈춘 자리에서 이어서
struct ResumeDriveIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "퇴근길 연습 계속"
    static var description = IntentDescription("멈춘 자리부터 퇴근길 듣기 연습을 이어서 들어요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = DriveSession.shared
        if session.isActive { session.play() } else { session.start() }
        return .result()
    }
}

/// "말문 다음" — 다음 문장
struct NextLineIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "다음 문장"
    static var description = IntentDescription("퇴근길 연습에서 다음 문장으로 넘어가요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        DriveSession.shared.next()
        return .result()
    }
}

/// "말문 다시" — 지금 문장 한 번 더
struct RepeatLineIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "한 번 더 듣기"
    static var description = IntentDescription("퇴근길 연습에서 지금 문장을 한 번 더 들어요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        DriveSession.shared.previous()
        return .result()
    }
}

// MARK: - 내 표현 (Spotlight · Siri 가 찾는 것)

/// 열어 달라는 내 표현. ContentView 가 '내 표현' 탭으로 옮기고, MyPhrasesView 가 연습 화면으로 열고 비운다.
@MainActor @Observable
final class PhraseOpenRequest {
    static let shared = PhraseOpenRequest()
    private init() { }
    var phraseID: UUID?
}

struct PhraseEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "내 표현")
    static let defaultQuery = PhraseQuery()

    let id: UUID
    let text: String
    let meaning: String
    let context: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(text)", subtitle: "\(meaning)")
    }

    init(_ phrase: MyPhrase) {
        id = phrase.id
        text = phrase.text
        meaning = phrase.meaning
        context = phrase.context
    }

    /// 지금 배우는 언어의 내 표현. 화면 없이 불려도 파일에서 읽는다 (→ DriveContent.phrases).
    @MainActor
    static func all() -> [PhraseEntity] {
        DriveContent.phrases().map(PhraseEntity.init)
    }

    /// Spotlight 에 싣는 표현을 지금 것에 맞춘다. 앱을 열 때와 뒤로 보낼 때 부른다.
    @MainActor
    static func reindex() async {
        guard #available(iOS 18.0, *) else { return }
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: PhraseEntity.self)
        try? await index.indexAppEntities(all())
    }
}

@available(iOS 18.0, *)
extension PhraseEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.textContent = [text, meaning, context].filter { !$0.isEmpty }.joined(separator: "\n")
        return set
    }
}

struct PhraseQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [PhraseEntity] {
        let wanted = Set(identifiers)
        return PhraseEntity.all().filter { wanted.contains($0.id) }
    }

    /// 문장 · 뜻 · 상황에서 찾는다 (대소문자 · 악센트 무시).
    @MainActor
    func entities(matching string: String) async throws -> [PhraseEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return PhraseEntity.all().filter { entity in
            [entity.text, entity.meaning, entity.context].contains {
                $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [PhraseEntity] {
        Array(PhraseEntity.all().prefix(20))
    }
}

/// 내 표현을 연습 화면으로 연다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenPhraseIntent: OpenIntent {
    static var title: LocalizedStringResource = "내 표현 열기"
    static var description = IntentDescription("저장한 표현을 골라 연습 화면으로 열어요.")

    @Parameter(title: "내 표현", description: "연습할 저장한 표현")
    var target: PhraseEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        PhraseOpenRequest.shared.phraseID = target.id
        return .result()
    }
}

struct MalmunShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDriveIntent(),
            phrases: ["\(.applicationName) 퇴근길 연습 시작"],
            shortTitle: "퇴근길 연습",
            systemImageName: "car.fill"
        )
        AppShortcut(
            intent: ResumeDriveIntent(),
            phrases: ["\(.applicationName) 계속"],
            shortTitle: "이어서 듣기",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: NextLineIntent(),
            phrases: ["\(.applicationName) 다음"],
            shortTitle: "다음 문장",
            systemImageName: "forward.end.fill"
        )
        AppShortcut(
            intent: RepeatLineIntent(),
            phrases: ["\(.applicationName) 다시"],
            shortTitle: "한 번 더",
            systemImageName: "gobackward"
        )
        AppShortcut(
            intent: PauseDriveIntent(),
            phrases: ["\(.applicationName) 연습 멈춰"],
            shortTitle: "연습 멈추기",
            systemImageName: "pause.fill"
        )
    }
}
