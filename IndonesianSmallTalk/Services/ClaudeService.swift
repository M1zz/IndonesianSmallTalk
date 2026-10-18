import Foundation

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case apiError(Int, String)
    case emptyResponse
    case invalidJSON(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:          return String(localized: "API 키를 입력해주세요.")
        case .networkError(let e):    return String(localized: "네트워크 오류: \(e.localizedDescription)")
        case .apiError(let c, _):     return String(localized: "API 오류 (\(c)). API 키를 확인해주세요.")
        case .emptyResponse:          return String(localized: "빈 응답을 받았어요. 다시 시도해주세요.")
        case .invalidJSON(let s):     return String(localized: "응답 파싱 실패: \(String(s.prefix(120)))…")
        }
    }
}

// MARK: - Claude API response shapes

private struct ClaudeAPIResponse: Decodable {
    struct Content: Decodable { let text: String }
    let content: [Content]
}

private struct RawScenario: Decodable {
    let title: String
    let titleKo: String
    let description: String
    let emoji: String
    let difficulty: String
    let rootNode: ConversationNodeData
    let vocabulary: [RawVocab]
    let grammarPoints: [RawGrammar]

    struct RawVocab: Decodable {
        let indonesian: String
        let romanization: String
        let korean: String
        let category: String
    }
    struct RawGrammarExample: Decodable {
        let indonesian: String
        let korean: String
    }
    struct RawGrammar: Decodable {
        let number: Int
        let titleId: String
        let titleKo: String
        let explanation: String
        let examples: [RawGrammarExample]
    }

    func toAIScenario(userPrompt: String) -> AIScenario {
        AIScenario(
            title: title,
            titleKo: titleKo,
            description: description,
            emoji: emoji,
            difficultyRaw: difficulty,
            rootNode: rootNode,
            vocabulary: vocabulary.map {
                VocabItem(indonesian: $0.indonesian, romanization: $0.romanization,
                          korean: $0.korean, category: $0.category)
            },
            grammarPoints: grammarPoints.map { g in
                GrammarPoint(
                    number: g.number, titleId: g.titleId, titleKo: g.titleKo,
                    explanation: g.explanation,
                    examples: g.examples.map { GrammarExample(indonesian: $0.indonesian, korean: $0.korean) }
                )
            },
            userPrompt: userPrompt
        )
    }
}

// MARK: - Service

actor ClaudeService {
    static let shared = ClaudeService()

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    // MARK: - Prompt language

    /// 프롬프트에 넣을 언어 설정 — 배우는 언어로 대화를 만들고, 뜻·설명은 화면 언어로.
    private struct PromptLanguages {
        let learning: AppLanguage
        let native: AppLanguage

        static var current: PromptLanguages { PromptLanguages(learning: AppLanguage.learning, native: AppLanguage.native) }

        /// 프롬프트용 영어 언어 이름
        static func englishName(_ lang: AppLanguage) -> String {
            switch lang {
            case .korean: return "Korean"
            case .english: return "English"
            case .japanese: return "Japanese"
            case .chinese: return "Simplified Chinese (Mandarin)"
            case .spanish: return "Spanish"
            case .indonesian: return "Indonesian (Bahasa Indonesia)"
            }
        }

        var learningName: String { Self.englishName(learning) }
        var nativeName: String { Self.englishName(native) }

        /// romanization 필드에 무엇을 넣을지 — 한국어 화면이면 한글 발음, 아니면 언어에 맞는 로마자(라틴 문자 언어는 빈 문자열)
        var romanizationSample: String {
            if native == .korean { return "Hangul pronunciation" }
            switch learning {
            case .japanese: return "romaji"
            case .chinese: return "pinyin"
            case .korean: return "romanization"
            default: return ""
            }
        }

        var romanizationRule: String {
            if native == .korean {
                return "romanization: Korean phonetics ONLY (Hangul) of the \(learningName) sentence, e.g. Indonesian \"Siapa kabar?\" → \"시아빠 까바르?\". NOT Latin romanization"
            }
            switch learning {
            case .japanese: return "romanization: Hepburn romaji of the Japanese sentence (e.g. \"Ogenki desu ka?\")"
            case .chinese: return "romanization: Hanyu Pinyin with tone marks (e.g. \"Nǐ hǎo ma?\")"
            case .korean: return "romanization: Revised Romanization of Korean (e.g. \"Annyeonghaseyo?\")"
            default: return "romanization: always an empty string \"\" (\(learningName) is written in Latin script)"
            }
        }

        /// 프롬프트 맨 앞의 역할 설명과 필드 의미
        var roleAndFields: String {
            """
            The user is a native \(nativeName) speaker learning \(learningName).
            Field meanings (keep these exact JSON key names even though they mention Indonesian/Korean):
            - "indonesian": the sentence/word in \(learningName) (the language being learned)
            - "korean": its meaning written in \(nativeName)
            - "title": the topic in \(learningName); "titleKo": the topic in \(nativeName)
            - "description", "category", "titleKo", "explanation": written in \(nativeName)
            - "titleId": the grammar pattern name in \(learningName)
            - "coachTipLabel", "coachTipText", "coachTipWhy": short coaching notes written in \(nativeName)
            - "difficulty": a fixed code, not translated
            """
        }
    }

    // Used when generating from a text topic description
    private func topicSystemPrompt(_ lang: PromptLanguages) -> String {
        let r = lang.romanizationSample
        return """
    You are a \(lang.learningName) language learning content creator for \(lang.nativeName) speakers. \
    Given a topic/request, generate a complete learning package as a SINGLE JSON object.

    \(lang.roleAndFields)

    Output this exact JSON structure (no markdown, no extra text, ONLY JSON):
    {
      "title": "Topic in \(lang.learningName)",
      "titleKo": "Topic in \(lang.nativeName)",
      "description": "one-line description in \(lang.nativeName)",
      "emoji": "single emoji",
      "difficulty": "Pemula",
      "rootNode": {
        "id": "xx_root",
        "speakerIsMe": false,
        "indonesian": "opening sentence in \(lang.learningName) (other speaker starts)",
        "korean": "meaning in \(lang.nativeName)",
        "romanization": "\(r)",
        "polarity": "neutral",
        "coachTipLabel": "technique name in \(lang.nativeName)",
        "coachTipText": "explanation in \(lang.nativeName)",
        "coachTipWhy": "reason in \(lang.nativeName)",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": true,
            "indonesian": "my positive reply",
            "korean": "...",
            "romanization": "\(r)",
            "polarity": "positive",
            "coachTipLabel": "...",
            "coachTipText": "...",
            "coachTipWhy": "...",
            "children": [
              {
                "id": "xx_a1",
                "speakerIsMe": false,
                "indonesian": "their follow-up",
                "korean": "...",
                "romanization": "...",
                "polarity": "positive",
                "coachTipLabel": null,
                "coachTipText": null,
                "coachTipWhy": null,
                "children": [
                  {
                    "id": "xx_a1a",
                    "speakerIsMe": true,
                    "indonesian": "my reply option A",
                    "korean": "...",
                    "romanization": "...",
                    "polarity": "positive",
                    "coachTipLabel": null,
                    "coachTipText": null,
                    "coachTipWhy": null,
                    "children": [
                      {
                        "id": "xx_a1a1",
                        "speakerIsMe": false,
                        "indonesian": "closing response",
                        "korean": "...",
                        "romanization": "...",
                        "polarity": "positive",
                        "coachTipLabel": null,
                        "coachTipText": null,
                        "coachTipWhy": null,
                        "children": []
                      }
                    ]
                  },
                  {
                    "id": "xx_a1b",
                    "speakerIsMe": true,
                    "indonesian": "my reply option B",
                    "korean": "...",
                    "romanization": "...",
                    "polarity": "neutral",
                    "coachTipLabel": null,
                    "coachTipText": null,
                    "coachTipWhy": null,
                    "children": [
                      {
                        "id": "xx_a1b1",
                        "speakerIsMe": false,
                        "indonesian": "their closing",
                        "korean": "...",
                        "romanization": "...",
                        "polarity": "neutral",
                        "coachTipLabel": null,
                        "coachTipText": null,
                        "coachTipWhy": null,
                        "children": []
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "id": "xx_b",
            "speakerIsMe": true,
            "indonesian": "my neutral/negative reply",
            "korean": "...",
            "romanization": "...",
            "polarity": "negative",
            "coachTipLabel": null,
            "coachTipText": null,
            "coachTipWhy": null,
            "children": [
              {
                "id": "xx_b1",
                "speakerIsMe": false,
                "indonesian": "their follow-up (different path)",
                "korean": "...",
                "romanization": "...",
                "polarity": "neutral",
                "coachTipLabel": null,
                "coachTipText": null,
                "coachTipWhy": null,
                "children": [
                  {
                    "id": "xx_b1a",
                    "speakerIsMe": true,
                    "indonesian": "my reply",
                    "korean": "...",
                    "romanization": "...",
                    "polarity": "positive",
                    "coachTipLabel": null,
                    "coachTipText": null,
                    "coachTipWhy": null,
                    "children": [
                      {
                        "id": "xx_b1a1",
                        "speakerIsMe": false,
                        "indonesian": "closing",
                        "korean": "...",
                        "romanization": "...",
                        "polarity": "positive",
                        "coachTipLabel": null,
                        "coachTipText": null,
                        "coachTipWhy": null,
                        "children": []
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      "vocabulary": [
        { "indonesian": "word in \(lang.learningName)", "romanization": "\(r)", "korean": "meaning in \(lang.nativeName)", "category": "part of speech in \(lang.nativeName)" }
      ],
      "grammarPoints": [
        {
          "number": 1,
          "titleId": "Pattern name in \(lang.learningName)",
          "titleKo": "Pattern name in \(lang.nativeName)",
          "explanation": "explanation in \(lang.nativeName)",
          "examples": [{ "indonesian": "example in \(lang.learningName)", "korean": "meaning in \(lang.nativeName)" }]
        }
      ]
    }

    TREE DEPTH RULES — follow exactly:
    - Root node is always the OTHER speaker (speakerIsMe: false) opening the conversation
    - Root must have 2–3 children (speakerIsMe: true) representing different ways I can respond
    - Each path must be EXACTLY 5 nodes deep from root (root=depth0, leaf=depth4):
        depth 0: root (other) → depth 1: my reply (me) → depth 2: their follow-up (other) → depth 3: my response (me) → depth 4: their closing (other, children:[])
    - At depth 1: 2–3 branches (positive / neutral / negative replies)
    - At depth 3: 2 branches under at least one depth-2 node (showing choice at that point)
    - Total nodes: 20–35
    - Strictly alternate speakers every level: speakerIsMe flips at every depth
    - All dialogue lines ("indonesian" fields) must be natural, everyday \(lang.learningName)
    - difficulty: "Pemula" (beginner), "Menengah" (intermediate), or "Mahir" (advanced) — use these exact codes
    - Node IDs: short prefix + letter/number (e.g. "rs_root", "rs_a", "rs_a1", "rs_a1a", "rs_a1a1")
    - polarity: "positive" = good/ideal, "negative" = awkward/less ideal, "neutral" = opener/factual
    - coachTip: provide for depth-1 nodes (my first replies) and 1–2 key strategy nodes; null elsewhere
    - \(lang.romanizationRule)
    - vocabulary: 15–20 items covering key words in the tree
    - grammarPoints: 3–4 key grammar patterns, explained in \(lang.nativeName)
    - Output ONLY valid JSON. No markdown, no explanation, no extra text.
    """
    }

    // Used when converting pasted HTML from a learning website
    private func htmlSystemPrompt(_ lang: PromptLanguages) -> String {
        let r = lang.romanizationSample
        return """
    You are a \(lang.learningName) language learning content creator for \(lang.nativeName) speakers. \
    The user will paste text extracted from a \(lang.learningName) language learning website. \
    Extract the actual conversation dialogues, vocabulary, and grammar patterns from the content \
    and convert them into a structured learning package as a SINGLE JSON object.

    \(lang.roleAndFields)

    Output this exact JSON structure (no markdown, no extra text, ONLY JSON):
    {
      "title": "Topic in \(lang.learningName)",
      "titleKo": "Topic in \(lang.nativeName)",
      "description": "one-line description in \(lang.nativeName)",
      "emoji": "single emoji",
      "difficulty": "Pemula",
      "rootNode": {
        "id": "xx_root",
        "speakerIsMe": false,
        "indonesian": "opening sentence from content",
        "korean": "meaning in \(lang.nativeName)",
        "romanization": "\(r)",
        "polarity": "neutral",
        "coachTipLabel": "technique name in \(lang.nativeName)",
        "coachTipText": "explanation in \(lang.nativeName)",
        "coachTipWhy": "reason in \(lang.nativeName)",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": true,
            "indonesian": "...",
            "korean": "...",
            "romanization": "\(r)",
            "polarity": "positive",
            "coachTipLabel": null,
            "coachTipText": null,
            "coachTipWhy": null,
            "children": [...]
          }
        ]
      },
      "vocabulary": [
        { "indonesian": "word in \(lang.learningName)", "romanization": "\(r)", "korean": "meaning in \(lang.nativeName)", "category": "part of speech in \(lang.nativeName)" }
      ],
      "grammarPoints": [
        {
          "number": 1,
          "titleId": "Pattern name in \(lang.learningName)",
          "titleKo": "Pattern name in \(lang.nativeName)",
          "explanation": "explanation in \(lang.nativeName)",
          "examples": [{ "indonesian": "example in \(lang.learningName)", "korean": "meaning in \(lang.nativeName)" }]
        }
      ]
    }

    TREE DEPTH RULES — follow exactly:
    - Root node is the OTHER speaker (speakerIsMe: false) — use real opening line from source
    - Root must have 2–3 children (speakerIsMe: true) representing different response approaches
    - Each path must be EXACTLY 5 nodes deep (root=depth0 to leaf=depth4):
        depth 0: root (other) → depth 1: my reply (me) → depth 2: their follow-up (other) → depth 3: my response (me) → depth 4: their closing (other, children:[])
    - At depth 1: 2–3 branches; at depth 3: 2 branches under at least one depth-2 node
    - Total nodes: 20–35
    - Strictly alternate speakers: speakerIsMe flips at every depth
    - Extract REAL dialogue lines from source — do not invent sentences not found in the content
    - difficulty: "Pemula" (beginner), "Menengah" (intermediate), or "Mahir" (advanced) — use these exact codes, based on content complexity
    - Node IDs: short prefix + letter/number (e.g. "mk_root", "mk_a", "mk_a1", "mk_a1a", "mk_a1a1")
    - polarity: "positive" = good/ideal, "negative" = awkward/less ideal, "neutral" = opener/factual
    - coachTip: provide for depth-1 nodes and 1–2 key strategy nodes; null elsewhere
    - \(lang.romanizationRule)
    - vocabulary: 15–20 items from source content
    - grammarPoints: 3–4 key grammar patterns, explained in \(lang.nativeName)
    - Output ONLY valid JSON. No markdown, no explanation.
    """
    }

    // MARK: - Public API

    func generate(prompt: String, apiKey: String) async throws -> AIScenario {
        let lang = PromptLanguages.current
        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 16000,
            "system": topicSystemPrompt(lang),
            "messages": [["role": "user", "content": "Generate a \(lang.learningName) scenario for: \(prompt)"]]
        ]
        return try await sendRequest(body: body, apiKey: apiKey, userPrompt: prompt, language: lang.learning)
    }

    func generateFromHTML(html: String, apiKey: String) async throws -> AIScenario {
        let lang = PromptLanguages.current
        let stripped = stripHTML(html)
        let truncated = String(stripped.prefix(12000))
        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 16000,
            "system": htmlSystemPrompt(lang),
            "messages": [["role": "user", "content": "Convert this \(lang.learningName) learning content:\n\n\(truncated)"]]
        ]
        return try await sendRequest(body: body, apiKey: apiKey, userPrompt: String(localized: "HTML 콘텐츠"), language: lang.learning)
    }

    // MARK: - Private

    private func sendRequest(body: [String: Any], apiKey: String, userPrompt: String, language: AppLanguage) async throws -> AIScenario {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw ClaudeError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeError.apiError(http.statusCode, msg)
        }

        let apiResp = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        guard let text = apiResp.content.first?.text, !text.isEmpty else {
            throw ClaudeError.emptyResponse
        }

        let jsonText = extractJSON(from: text)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeError.invalidJSON(text)
        }

        do {
            let raw = try JSONDecoder().decode(RawScenario.self, from: jsonData)
            var scenario = raw.toAIScenario(userPrompt: userPrompt)
            scenario.languageCode = language.rawValue
            return scenario
        } catch let decodeError as DecodingError {
            // Surface the exact field that failed so we can debug prompt issues
            let context: String
            switch decodeError {
            case .keyNotFound(let key, _):
                context = String(localized: "필드 누락: '\(key.stringValue)'")
            case .typeMismatch(_, let ctx):
                context = String(localized: "타입 불일치: \(ctx.codingPath.map(\.stringValue).joined(separator: "."))")
            case .valueNotFound(_, let ctx):
                context = String(localized: "값 없음: \(ctx.codingPath.map(\.stringValue).joined(separator: "."))")
            case .dataCorrupted(let ctx):
                context = String(localized: "데이터 손상: \(ctx.debugDescription)")
            @unknown default:
                context = decodeError.localizedDescription
            }
            throw ClaudeError.invalidJSON(context)
        } catch {
            throw ClaudeError.invalidJSON(error.localizedDescription)
        }
    }

    private func extractJSON(from text: String) -> String {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = stripped.firstIndex(of: "{"),
           let end = stripped.lastIndex(of: "}") {
            return String(stripped[start...end])
        }
        return stripped
    }

    private func stripHTML(_ html: String) -> String {
        var result = html
        // Remove script/style blocks entirely
        for tag in ["script", "style", "head"] {
            while let open = result.range(of: "<\(tag)", options: .caseInsensitive),
                  let close = result.range(of: "</\(tag)>", options: .caseInsensitive,
                                           range: open.lowerBound..<result.endIndex) {
                result.removeSubrange(open.lowerBound...close.upperBound)
            }
        }
        // Block tags → newline
        for tag in ["</p>", "</div>", "</li>", "</tr>", "<br>", "<br/>", "<br />"] {
            result = result.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        // Strip remaining tags
        while let open = result.range(of: "<"),
              let close = result.range(of: ">", range: open.upperBound..<result.endIndex) {
            result.removeSubrange(open.lowerBound...close.upperBound)
        }
        // Collapse empty lines
        return result.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
