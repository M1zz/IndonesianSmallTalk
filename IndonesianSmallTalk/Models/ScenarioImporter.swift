import Foundation

/// 붙여 넣은 대화 글을 내 시나리오로 바꾼다.
///
/// 형식 (한 줄에 한 마디, 빈 줄은 무시):
/// ```
/// 제목: Di kafe / 카페에서        ← 없어도 된다
/// A: Mau pesan apa? / 뭐 주문하실래요?
/// B: Satu kopi susu, ya. / 카페라테 하나요.
/// ```
/// - `A:` `B:` 로 누가 말하는지 정한다. 기본은 A = 상대방, B = 나 (화면에서 바꿀 수 있다).
///   `나:` `상대:` 처럼 직접 써도 된다.
/// - 문장과 뜻은 ` / ` 또는 `|` 로 나눈다. 뜻이 없어도 되고, 다음 줄에 `(뜻)` 처럼 괄호로 써도 된다.
/// - 앞의 번호(`1.`), 글머리(`-`), 굵게(`**A:**`) 는 지운다.
/// - 같은 사람이 연달아 말하면 한 마디로 합친다. (연습 화면은 주고받는 순서를 가정한다)
enum ScenarioImporter {

    struct Line: Identifiable, Equatable {
        let id = UUID()
        let lineNumber: Int
        let isFirstLabel: Bool          // A(첫 번째 사람)로 표시된 줄인지
        var speaker: ConversationNode.Speaker
        var text: String
        var meaning: String
    }

    struct Issue: Identifiable, Equatable {
        let id = UUID()
        let lineNumber: Int
        let raw: String
        let message: String
    }

    struct Result {
        var title: String = ""
        var titleMeaning: String = ""
        var lines: [Line] = []
        var issues: [Issue] = []
        var mergedCount = 0             // 같은 사람이 연달아 말해 합친 줄 수
        var isEmpty: Bool { lines.isEmpty }
    }

    // MARK: - Parse

    /// firstIsOther: A 로 표시된 사람이 상대방인지
    static func parse(_ input: String, firstIsOther: Bool = true) -> Result {
        var result = Result()
        let rawLines = input
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        for (i, raw) in rawLines.enumerated() {
            let number = i + 1
            let line = clean(raw)
            if line.isEmpty || line.hasPrefix("```") { continue }

            // 제목
            if let rest = stripPrefix(line, ["제목:", "제목 :", "title:", "Title:", String(localized: "제목") + ":", "#"]) {
                let (t, m) = splitMeaning(rest)
                result.title = t
                result.titleMeaning = m
                continue
            }

            // 앞 줄의 뜻을 괄호로 따로 쓴 경우: (뜻)
            if line.hasPrefix("("), line.hasSuffix(")"), line.count > 2,
               let last = result.lines.indices.last, result.lines[last].meaning.isEmpty {
                result.lines[last].meaning = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                continue
            }

            guard let (label, rest) = speakerLabel(line) else {
                result.issues.append(Issue(lineNumber: number, raw: raw,
                                           message: String(localized: "누가 말하는지 알 수 없어요. A: 또는 B: 로 시작해 주세요.")))
                continue
            }
            let (text, meaning) = splitMeaning(rest)
            guard !text.isEmpty else {
                result.issues.append(Issue(lineNumber: number, raw: raw,
                                           message: String(localized: "문장이 비어 있어요.")))
                continue
            }

            let speaker: ConversationNode.Speaker
            switch label {
            case .first: speaker = firstIsOther ? .other : .me
            case .second: speaker = firstIsOther ? .me : .other
            case .me: speaker = .me
            case .other: speaker = .other
            }

            // 같은 사람이 연달아 말하면 앞 줄에 붙인다
            if let last = result.lines.indices.last, result.lines[last].speaker == speaker {
                result.lines[last].text += " " + text
                if !meaning.isEmpty {
                    let prev = result.lines[last].meaning
                    result.lines[last].meaning = prev.isEmpty ? meaning : prev + " " + meaning
                }
                result.mergedCount += 1
                continue
            }

            result.lines.append(Line(lineNumber: number, isFirstLabel: label == .first,
                                     speaker: speaker, text: text, meaning: meaning))
        }
        return result
    }

    private enum Label { case first, second, me, other }

    private static let labels: [(String, Label)] = [
        ("A", .first), ("B", .second),
        ("나", .me), ("me", .me), ("Me", .me), ("ME", .me),
        ("상대방", .other), ("상대", .other), ("other", .other), ("Other", .other)
    ]

    /// 줄 앞의 "A:" 같은 말한 사람 표시를 떼어 낸다
    private static func speakerLabel(_ line: String) -> (Label, String)? {
        for (name, label) in labels {
            for sep in [":", "：", ")", "."] {
                let prefix = name + sep
                if line.hasPrefix(prefix) {
                    let rest = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                    return (label, rest)
                }
            }
        }
        return nil
    }

    /// 번호·글머리·마크다운 굵게·스마트 따옴표를 정리
    private static func clean(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        s = s.replacingOccurrences(of: "**", with: "")
        s = s.replacingOccurrences(of: "\u{201C}", with: "\"").replacingOccurrences(of: "\u{201D}", with: "\"")
        s = s.replacingOccurrences(of: "\u{2018}", with: "'").replacingOccurrences(of: "\u{2019}", with: "'")
        for bullet in ["- ", "* ", "• ", "· "] where s.hasPrefix(bullet) {
            s = String(s.dropFirst(bullet.count))
        }
        // "1. A: ..." / "1) A: ..." 의 번호
        if let range = s.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
            s.removeSubrange(range)
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    private static func stripPrefix(_ s: String, _ prefixes: [String]) -> String? {
        for p in prefixes where s.hasPrefix(p) {
            return String(s.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    /// "문장 / 뜻" 또는 "문장 | 뜻"
    private static func splitMeaning(_ s: String) -> (String, String) {
        for sep in [" / ", " | ", "|"] {   // 맨 "/" 는 24/7 같은 문장을 깨뜨려서 뺀다
            if let r = s.range(of: sep) {
                let text = s[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
                let meaning = s[r.upperBound...].trimmingCharacters(in: .whitespaces)
                return (text, meaning)
            }
        }
        return (s.trimmingCharacters(in: .whitespaces), "")
    }

    // MARK: - Save

    /// 첫 마디는 시나리오의 시작 문장, 나머지는 앞 마디에 이어 붙는 사용자 대답으로 저장한다.
    @MainActor
    @discardableResult
    static func save(
        _ result: Result,
        title: String,
        titleMeaning: String,
        emoji: String,
        scenarioStore: UserScenarioStore,
        replyStore: UserReplyStore
    ) -> UserScenario? {
        guard let first = result.lines.first else { return nil }
        let scenario = UserScenario(
            title: title,
            titleKo: titleMeaning,
            description: String(localized: "가져온 대화 · \(result.lines.count)마디"),
            emoji: emoji.isEmpty ? "💬" : emoji,
            difficultyRaw: (result.lines.count > 8
                            ? ConversationScenario.Difficulty.intermediate
                            : ConversationScenario.Difficulty.beginner).rawValue,
            openerSpeakerIsOther: first.speaker == .other,
            openingIndonesian: first.text,
            openingKorean: first.meaning,
            openingRomanization: "",
            languageCode: AppLanguage.learning.rawValue
        )
        scenarioStore.add(scenario)

        var parentId = scenario.rootNodeId
        let base = Date()
        for (i, line) in result.lines.dropFirst().enumerated() {
            let reply = UserReply(
                parentNodeId: parentId,
                indonesian: line.text,
                korean: line.meaning,
                speakerRaw: line.speaker == .me ? "me" : "other",
                createdAt: base.addingTimeInterval(Double(i) * 0.001)
            )
            replyStore.add(reply)
            parentId = "user-\(reply.id.uuidString)"
        }
        return scenario
    }

    // MARK: - Prompt

    /// ChatGPT 같은 AI 에 붙여 넣으면 이 형식으로 대화를 만들어 주는 요청문
    static func prompt(situation: String, language: AppLanguage = AppLanguage.learning) -> String {
        let learning = Locale(identifier: "en").localizedString(forLanguageCode: language.rawValue == "zh-Hans" ? "zh" : language.rawValue) ?? language.endonym
        let native = Locale(identifier: "en").localizedString(forLanguageCode: AppLanguage.native.rawValue == "zh-Hans" ? "zh" : AppLanguage.native.rawValue) ?? AppLanguage.native.endonym
        let place = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        Write a short, natural everyday conversation in \(learning)\(place.isEmpty ? "" : " for this situation: \(place)").
        8 to 12 lines, alternating between two people. A is the other person, B is me (the learner).
        Output plain text only, exactly in this format, one line per turn, nothing else:

        Title: <title in \(learning)> / <title in \(native)>
        A: <sentence in \(learning)> / <meaning in \(native)>
        B: <sentence in \(learning)> / <meaning in \(native)>
        """
    }
}
