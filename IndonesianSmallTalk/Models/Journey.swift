import Foundation

// MARK: - Time Slot (하루를 6칸으로 나눈 시간대)

enum TimeSlot: Int, CaseIterable, Identifiable {
    case earlyMorning = 0   // 06–09
    case morning            // 09–12
    case lunch              // 12–15
    case afternoon          // 15–18
    case evening            // 18–21
    case night              // 21–06

    var id: Int { rawValue }

    var labelKo: String {
        [String(localized: "아침"), String(localized: "오전"), String(localized: "점심"),
         String(localized: "오후"), String(localized: "저녁"), String(localized: "밤")][rawValue]
    }

    var rangeLabel: String {
        ["06–09", "09–12", "12–15", "15–18", "18–21", "21–06"][rawValue]
    }

    var emoji: String {
        ["🌅", "☀️", "🍽️", "🌤️", "🌆", "🌙"][rawValue]
    }


    static func containing(hour: Int) -> TimeSlot {
        switch hour {
        case 6..<9:   return .earlyMorning
        case 9..<12:  return .morning
        case 12..<15: return .lunch
        case 15..<18: return .afternoon
        case 18..<21: return .evening
        default:      return .night
        }
    }

}

// MARK: - Journey Stop (타임테이블의 한 칸)

/// 하루 코스 안의 한 장면. 시간 + 장소 + 그 장소에서 벌어지는 대화 시나리오.
struct JourneyStop: Identifiable {
    let id: String              // 진행률 저장 키 (예: "trip-01")
    let time: String            // "09:00"
    let emoji: String
    let place: String           // Bahasa Indonesia 장소명
    let placeKo: String         // 한국어 장소명
    let situation: String       // 한 줄 상황 설명 (한국어)
    let transitNote: String?    // 다음 장소까지 이동 메모 (마지막 칸은 nil)
    let scenario: ConversationScenario

    /// 한국어 원문을 받아 화면 언어 번역(ContentTranslations)으로 채운다.
    init(id: String, time: String, emoji: String, place: String, placeKo: String,
         situation: String, transitNote: String?, scenario: ConversationScenario) {
        self.id = id
        self.time = time
        self.emoji = emoji
        self.place = place
        self.placeKo = ContentTranslations.text(ContentKey.stop(id, "place"), korean: placeKo)
        self.situation = ContentTranslations.text(ContentKey.stop(id, "situation"), korean: situation)
        self.transitNote = transitNote.map { ContentTranslations.text(ContentKey.stop(id, "transit"), korean: $0) }
        self.scenario = scenario
    }

    /// "09:00" → 9
    var hour: Int { Int(time.prefix(2)) ?? 0 }
    /// "09:30" → 30
    var minute: Int { Int(time.suffix(2)) ?? 0 }
    /// 하루 시작(06:00)을 0으로 둔 분 단위 위치. 밤 시간대 정렬용.
    var minutesOfDay: Int { hour * 60 + minute }
    var slot: TimeSlot { TimeSlot.containing(hour: hour) }
}

// MARK: - Journey Course (하루 코스)

/// 여러 장면을 시간 순으로 엮은 하루 코스.
struct JourneyCourse: Identifiable, Hashable {
    let id: String
    let title: String           // Bahasa Indonesia
    let titleKo: String
    let description: String     // 한국어 소개
    let emoji: String
    let difficulty: ConversationScenario.Difficulty
    /// 이 코스가 실제로 벌어지는 요일 (Calendar.weekday: 1=일 … 7=토). 비어 있으면 '아무 날이나'.
    let weekdays: [Int]
    /// "평일 · 월–금" 처럼 화면에 보여줄 요일 설명
    let dayLabelKo: String
    let stops: [JourneyStop]

    /// 한국어 원문을 받아 화면 언어 번역(ContentTranslations)으로 채운다.
    init(id: String, title: String, titleKo: String, description: String, emoji: String,
         difficulty: ConversationScenario.Difficulty, weekdays: [Int], dayLabelKo: String, stops: [JourneyStop]) {
        self.id = id
        self.title = title
        self.titleKo = ContentTranslations.text(ContentKey.course(id, "title"), korean: titleKo)
        self.description = ContentTranslations.text(ContentKey.course(id, "description"), korean: description)
        self.emoji = emoji
        self.difficulty = difficulty
        self.weekdays = weekdays
        self.dayLabelKo = ContentTranslations.text(ContentKey.course(id, "dayLabel"), korean: dayLabelKo)
        self.stops = stops
    }

    var isAnyDay: Bool { weekdays.isEmpty }

    func stops(in slot: TimeSlot) -> [JourneyStop] {
        stops.filter { $0.slot == slot }
    }

    var timeRange: String {
        guard let first = stops.first, let last = stops.last else { return "" }
        return "\(first.time) – \(last.time)"
    }

    var stopCount: Int { stops.count }

    static func == (lhs: JourneyCourse, rhs: JourneyCourse) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Progress Store

/// 코스 안에서 어떤 장면을 끝냈는지 저장한다. (stopID → 점수)
@MainActor
final class JourneyProgressStore: ObservableObject {
    @Published private(set) var completed: [String: Int] = [:]

    private let storageKey = "journeyProgress.v1"

    init() { load() }

    func isDone(_ stopID: String) -> Bool { completed[stopID] != nil }

    func score(for stopID: String) -> Int? { completed[stopID] }

    /// 같은 장면을 다시 하면 더 높은 점수만 남긴다.
    func complete(_ stopID: String, score: Int) {
        if let existing = completed[stopID], existing >= score { return }
        completed[stopID] = score
        save()
    }

    func doneCount(in course: JourneyCourse) -> Int {
        course.stops.reduce(0) { $0 + (isDone($1.id) ? 1 : 0) }
    }

    func doneCount(in courses: [JourneyCourse]) -> Int {
        courses.reduce(0) { $0 + doneCount(in: $1) }
    }

    func totalCount(in courses: [JourneyCourse]) -> Int {
        courses.reduce(0) { $0 + $1.stopCount }
    }

    func progress(in course: JourneyCourse) -> Double {
        guard !course.stops.isEmpty else { return 0 }
        return Double(doneCount(in: course)) / Double(course.stops.count)
    }

    /// 아직 끝내지 않은 첫 장면 (없으면 nil)
    func nextStop(in course: JourneyCourse) -> JourneyStop? {
        course.stops.first { !isDone($0.id) }
    }

    func reset(course: JourneyCourse) {
        for stop in course.stops { completed[stop.id] = nil }
        save()
    }

    private func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] else { return }
        completed = dict
    }

    private func save() {
        UserDefaults.standard.set(completed, forKey: storageKey)
    }
}
