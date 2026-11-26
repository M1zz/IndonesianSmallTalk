//
//  MalmunLogicTests.swift
//  말문
//
//  말문의 값이 달린 셈들 — 말한 문장을 알아듣는 유사도, 붙여 넣은 대화 읽기,
//  연속 연습 일수, 시간대 · 언어 고르기.
//

import XCTest
@testable import IndonesianSmallTalk

@MainActor
final class MalmunLogicTests: XCTestCase {

    private var savedLearning: String?

    override func setUp() async throws {
        savedLearning = LanguagePrefs.defaults.string(forKey: LanguagePrefs.learningKey)
        let spaced = AppLanguage.native == .indonesian ? AppLanguage.english : .indonesian
        AppLanguage.learning = spaced
    }

    override func tearDown() async throws {
        LanguagePrefs.defaults.set(savedLearning, forKey: LanguagePrefs.learningKey)
    }

    // MARK: - 알아듣기

    func testNormalizeDropsPunctuationCaseAndExtraSpaces() {
        XCTAssertEqual(SpeechManager.normalizeForMatch("  Apa   kabar?!  "), "apa kabar")
        XCTAssertEqual(SpeechManager.normalizeForMatch("Saya mau 2 kopi, ya 😊"), "saya mau 2 kopi ya")
    }

    func testIdenticalSentenceScoresFull() {
        XCTAssertEqual(SpeechManager.similarityScore(spoken: "Apa kabar?", target: "apa kabar"), 1, accuracy: 1e-9)
    }

    func testCompletelyDifferentSentenceScoresLow() {
        let score = SpeechManager.similarityScore(spoken: "terima kasih", target: "selamat pagi")
        XCTAssertLessThan(score, 0.2, "매칭 문턱(0.2)을 넘지 않아야 한다")
    }

    func testCloseMispronunciationStillPassesTheThreshold() {
        let score = SpeechManager.similarityScore(spoken: "saya mau pesan kopi susu", target: "Saya mau pesan kopi susu, ya.")
        XCTAssertGreaterThan(score, 0.8)
        let typo = SpeechManager.similarityScore(spoken: "sayamau pesen kopi", target: "saya mau pesan kopi")
        XCTAssertGreaterThan(typo, 0.2)
        XCTAssertLessThan(typo, 1)
    }

    func testEmptyInputsDoNotCrashAndScoreZero() {
        XCTAssertEqual(SpeechManager.similarityScore(spoken: "", target: "apa kabar"), 0)
        XCTAssertEqual(SpeechManager.similarityScore(spoken: "apa", target: ""), 0)
        XCTAssertEqual(SpeechManager.similarityScore(spoken: "", target: "!!!"), 0)
    }

    func testScoreIsBetweenZeroAndOne() {
        let pairs = [("a", "abc def"), ("kopi kopi kopi", "kopi"), ("xyz", "a b c d e f g")]
        for (spoken, target) in pairs {
            let s = SpeechManager.similarityScore(spoken: spoken, target: target)
            XCTAssertGreaterThanOrEqual(s, 0)
            XCTAssertLessThanOrEqual(s, 1)
        }
    }

    func testLanguagesWithoutSpacesAreComparedByCharacter() {
        AppLanguage.learning = AppLanguage.native == .japanese ? .chinese : .japanese
        // 띄어 쓰지 않는 말을 낱말로 나누면 문장 전체가 한 낱말이라, 한 글자만 틀려도 낱말 점수가 0 이 된다.
        let score = SpeechManager.similarityScore(spoken: "コーヒーをください", target: "コーヒーください")
        XCTAssertGreaterThan(score, 0.8)
    }

    // MARK: - 붙여 넣은 대화

    func testParsesTitleSpeakersAndMeanings() {
        let result = ScenarioImporter.parse("""
        제목: Di kafe / 카페에서
        A: Mau pesan apa? / 뭐 주문하실래요?
        B: Satu kopi susu, ya. | 카페라테 하나요.
        """)
        XCTAssertEqual(result.title, "Di kafe")
        XCTAssertEqual(result.titleMeaning, "카페에서")
        XCTAssertEqual(result.lines.count, 2)
        XCTAssertEqual(result.lines[0].speaker, .other)
        XCTAssertEqual(result.lines[0].text, "Mau pesan apa?")
        XCTAssertEqual(result.lines[0].meaning, "뭐 주문하실래요?")
        XCTAssertEqual(result.lines[1].speaker, .me)
        XCTAssertEqual(result.lines[1].meaning, "카페라테 하나요.")
        XCTAssertTrue(result.issues.isEmpty)
    }

    func testFlippingWhoIsFirstSwapsSpeakers() {
        let result = ScenarioImporter.parse("A: Halo\nB: Hai", firstIsOther: false)
        XCTAssertEqual(result.lines.map(\.speaker), [.me, .other])
    }

    func testCleansNumbersBulletsAndBold() {
        let result = ScenarioImporter.parse("""
        1. **A:** Selamat pagi
        - B: Pagi juga
        2) 상대: Apa kabar?
        """)
        XCTAssertEqual(result.lines.map(\.text), ["Selamat pagi", "Pagi juga", "Apa kabar?"])
        XCTAssertEqual(result.lines.map(\.speaker), [.other, .me, .other])
    }

    func testMeaningOnNextLineInParentheses() {
        let result = ScenarioImporter.parse("A: Terima kasih\n(고마워요)\nB: Sama-sama")
        XCTAssertEqual(result.lines.first?.meaning, "고마워요")
        XCTAssertEqual(result.lines.count, 2)
    }

    func testSameSpeakerTwiceIsMergedIntoOneTurn() {
        let result = ScenarioImporter.parse("A: Halo / 안녕\nA: Apa kabar? / 잘 지내?\nB: Baik")
        XCTAssertEqual(result.lines.count, 2)
        XCTAssertEqual(result.lines[0].text, "Halo Apa kabar?")
        XCTAssertEqual(result.lines[0].meaning, "안녕 잘 지내?")
        XCTAssertEqual(result.mergedCount, 1)
    }

    func testSlashInsideSentenceIsNotAMeaningSeparator() {
        let result = ScenarioImporter.parse("A: Buka 24/7")
        XCTAssertEqual(result.lines.first?.text, "Buka 24/7")
        XCTAssertEqual(result.lines.first?.meaning, "")
    }

    func testUnlabelledAndEmptyLinesAreReportedWithLineNumbers() {
        let result = ScenarioImporter.parse("A: Halo\n\nHalo tanpa label\nB:   ")
        XCTAssertEqual(result.lines.count, 1)
        XCTAssertEqual(result.issues.map(\.lineNumber), [3, 4])
    }

    func testCodeFencesAndWindowsLineEndingsAreIgnored() {
        let result = ScenarioImporter.parse("```\r\nA: Halo\r\nB: Hai\r\n```")
        XCTAssertEqual(result.lines.map(\.text), ["Halo", "Hai"])
        XCTAssertTrue(result.issues.isEmpty)
    }

    // MARK: - 연습 기록

    private func record(_ date: Date, lines: Int = 3) -> PracticeRecord {
        PracticeRecord(date: date, language: "id", scenarioKey: "", title: "", titleMeaning: "",
                       mode: .text, score: nil, lines: lines)
    }

    func testStreakCountsBackFromTodayOrYesterday() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 27, hour: 9))!
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: -offset, to: now)! }

        XCTAssertEqual(PracticeHistoryStore.Stats(records: [day(0), day(1), day(2), day(4)].map { record($0) },
                                                  now: now, calendar: cal).currentStreak, 3)
        XCTAssertEqual(PracticeHistoryStore.Stats(records: [day(1), day(2)].map { record($0) },
                                                  now: now, calendar: cal).currentStreak, 2,
                       "아침에 아직 안 했어도 어제까지의 연속은 살아 있다")
        XCTAssertEqual(PracticeHistoryStore.Stats(records: [day(2), day(3)].map { record($0) },
                                                  now: now, calendar: cal).currentStreak, 0)
        XCTAssertEqual(PracticeHistoryStore.Stats(records: [day(0), day(0)].map { record($0) },
                                                  now: now, calendar: cal).currentStreak, 1,
                       "하루에 두 번 해도 하루다")
    }

    func testStatsTotals() {
        let stats = PracticeHistoryStore.Stats(records: [record(Date(), lines: 4), record(Date(), lines: 6)])
        XCTAssertEqual(stats.totalSessions, 2)
        XCTAssertEqual(stats.linesPracticed, 10)
        XCTAssertEqual(stats.thisWeekCount, 2)
    }

    func testTipMomentsAreBiggestFirstAndOnlyOncePassed() {
        XCTAssertTrue(MalmunTipMoments.reached(sessions: 29, lines: 299).isEmpty)
        XCTAssertEqual(MalmunTipMoments.reached(sessions: 120, lines: 300).map(\.id),
                       ["sessions.100", "sessions.30", "lines.300"])
    }

    // MARK: - 시간대 · 언어

    func testTimeSlotBoundaries() {
        XCTAssertEqual(TimeSlot.containing(hour: 6), .earlyMorning)
        XCTAssertEqual(TimeSlot.containing(hour: 8), .earlyMorning)
        XCTAssertEqual(TimeSlot.containing(hour: 12), .lunch)
        XCTAssertEqual(TimeSlot.containing(hour: 20), .evening)
        XCTAssertEqual(TimeSlot.containing(hour: 21), .night)
        XCTAssertEqual(TimeSlot.containing(hour: 3), .night)
    }

    func testLanguageFromLocaleCode() {
        XCTAssertEqual(AppLanguage(localeCode: "zh-Hant-TW"), .chinese)
        XCTAssertEqual(AppLanguage(localeCode: "id_ID"), .indonesian)
        XCTAssertEqual(AppLanguage(localeCode: "es-419"), .spanish)
        XCTAssertNil(AppLanguage(localeCode: "fr-FR"))
    }

    func testLearningLanguageIsNeverTheScreenLanguage() {
        LanguagePrefs.defaults.set(AppLanguage.native.rawValue, forKey: LanguagePrefs.learningKey)
        XCTAssertNotEqual(AppLanguage.learning, AppLanguage.native)
        XCTAssertFalse(AppLanguage.learnable.contains(AppLanguage.native))
    }
}
