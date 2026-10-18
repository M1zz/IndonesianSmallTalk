import Foundation

// MARK: - Practice Record

/// 연습 한 번의 기록. 언어마다 따로 보여 주려고 language 를 같이 저장한다.
struct PracticeRecord: Identifiable, Codable, Equatable {
    enum Mode: String, Codable, CaseIterable {
        case text, voice, pronunciation, drive, script

        var icon: String {
            switch self {
            case .text: return "text.bubble.fill"
            case .voice: return "mic.fill"
            case .pronunciation: return "waveform"
            case .drive: return "car.fill"
            case .script: return "doc.plaintext.fill"
            }
        }

        var label: String {
            switch self {
            case .text: return String(localized: "대화 연습")
            case .voice: return String(localized: "음성 연습")
            case .pronunciation: return String(localized: "발음 연습")
            case .drive: return String(localized: "운전 모드")
            case .script: return String(localized: "대본 보기")
            }
        }
    }

    var id: UUID = UUID()
    var date: Date = Date()
    var language: String          // AppLanguage.rawValue
    var scenarioKey: String       // ConversationScenario.key (발음 연습처럼 시나리오가 없으면 빈 문자열)
    var title: String             // 배우는 언어 제목
    var titleMeaning: String      // 화면 언어 뜻
    var mode: Mode
    var score: Int?               // 0~100, 점수가 없는 모드는 nil
    var lines: Int                // 말하거나 들은 문장 수
}

// MARK: - Store

@MainActor
final class PracticeHistoryStore: ObservableObject {
    static let shared = PracticeHistoryStore()

    /// 모든 언어의 기록 (최근 것이 앞)
    @Published private(set) var allRecords: [PracticeRecord] = []

    /// 너무 오래 쌓이지 않게 최근 것만 남긴다
    private let maxRecords = 2000

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("practicehistory.json")
    }()

    private init() {
        load()
    }

    // MARK: Record

    /// 연습이 끝날 때 한 번 부른다. lines 가 0 이면 기록하지 않는다.
    func record(
        scenario: ConversationScenario,
        mode: PracticeRecord.Mode,
        score: Int? = nil,
        lines: Int
    ) {
        record(language: scenario.language, scenarioKey: scenario.key,
               title: scenario.title, titleMeaning: scenario.titleKo,
               mode: mode, score: score, lines: lines)
    }

    func record(
        language: AppLanguage = AppLanguage.learning,
        scenarioKey: String = "",
        title: String,
        titleMeaning: String = "",
        mode: PracticeRecord.Mode,
        score: Int? = nil,
        lines: Int
    ) {
        guard lines > 0 else { return }
        let rec = PracticeRecord(
            language: language.rawValue,
            scenarioKey: scenarioKey,
            title: title,
            titleMeaning: titleMeaning,
            mode: mode,
            score: score.map { min(max($0, 0), 100) },
            lines: lines
        )
        allRecords.insert(rec, at: 0)
        if allRecords.count > maxRecords { allRecords.removeLast(allRecords.count - maxRecords) }
        save()
    }

    func delete(id: UUID) {
        allRecords.removeAll { $0.id == id }
        save()
    }

    // MARK: Query

    func records(for language: AppLanguage) -> [PracticeRecord] {
        allRecords.filter { $0.language == language.rawValue }
    }

    func stats(for language: AppLanguage) -> Stats {
        Stats(records: records(for: language))
    }

    /// 기록 목록에서 바로 계산하는 간단한 통계
    struct Stats {
        let totalSessions: Int
        let linesPracticed: Int
        let currentStreak: Int     // 오늘(또는 어제)까지 이어진 연속 연습 일수
        let thisWeekCount: Int     // 이번 주(달력 기준) 연습 횟수

        init(records: [PracticeRecord], now: Date = Date(), calendar: Calendar = .current) {
            totalSessions = records.count
            linesPracticed = records.reduce(0) { $0 + $1.lines }

            let days = Set(records.map { calendar.startOfDay(for: $0.date) })
            var day = calendar.startOfDay(for: now)
            // 오늘 아직 안 했으면 어제부터 센다 (연속 기록이 아침에 0 으로 보이지 않게)
            if !days.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
                day = yesterday
            }
            var streak = 0
            while days.contains(day) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            }
            currentStreak = streak

            if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
                thisWeekCount = records.filter { week.contains($0.date) }.count
            } else {
                thisWeekCount = 0
            }
        }
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([PracticeRecord].self, from: data) {
            allRecords = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(allRecords) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
