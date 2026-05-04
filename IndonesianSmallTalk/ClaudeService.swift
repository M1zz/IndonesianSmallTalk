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
        case .missingAPIKey:          return "API 키를 입력해주세요."
        case .networkError(let e):    return "네트워크 오류: \(e.localizedDescription)"
        case .apiError(let c, _):     return "API 오류 (\(c)). API 키를 확인해주세요."
        case .emptyResponse:          return "빈 응답을 받았어요. 다시 시도해주세요."
        case .invalidJSON(let s):     return "응답 파싱 실패: \(s.prefix(120))…"
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

    // Used when generating from a text topic description
    private let topicSystemPrompt = """
    You are an Indonesian language learning content creator for Korean speakers. \
    Given a topic/request, generate a complete learning package as a SINGLE JSON object.

    Output this exact JSON structure (no markdown, no extra text, ONLY JSON):
    {
      "title": "Topic in Bahasa Indonesia",
      "titleKo": "주제 (한국어)",
      "description": "한 줄 설명",
      "emoji": "single emoji",
      "difficulty": "Pemula",
      "rootNode": {
        "id": "xx_root",
        "speakerIsMe": true,
        "indonesian": "opening sentence",
        "korean": "한국어 번역",
        "romanization": "한글 발음",
        "polarity": "neutral",
        "coachTipLabel": "Strategi Pembuka",
        "coachTipText": "explanation in Indonesian",
        "coachTipWhy": "reason in Indonesian",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": false,
            "indonesian": "...",
            "korean": "...",
            "romanization": "한글 발음",
            "polarity": "positive",
            "coachTipLabel": null,
            "coachTipText": null,
            "coachTipWhy": null,
            "children": [...]
          }
        ]
      },
      "vocabulary": [
        { "indonesian": "word", "romanization": "한글 발음", "korean": "뜻", "category": "동사" }
      ],
      "grammarPoints": [
        {
          "number": 1,
          "titleId": "Pattern name",
          "titleKo": "패턴 이름",
          "explanation": "한국어로 설명",
          "examples": [{ "indonesian": "example", "korean": "한국어" }]
        }
      ]
    }

    Rules:
    - difficulty: "Pemula", "Menengah", or "Mahir"
    - Node IDs: short + letter/number (e.g. "mk_root", "mk_a", "mk_a1", "mk_b")
    - Strictly alternate speakers: speakerIsMe:true → children all false, and vice versa
    - 2–3 top-level branches from root; each branch 3–4 levels deep
    - polarity: "positive" = good move, "negative" = realistic but less ideal, "neutral" = opener
    - coachTip: provide for key nodes (strategy nodes), null for simple response nodes
    - romanization: Korean phonetics ONLY (한글), e.g. "아빠까 이니 쁘다스?" NOT Latin
    - vocabulary: 15–25 items covering ALL non-trivial words in the tree
    - grammarPoints: 3–5 points covering key patterns from the conversation
    - Output ONLY valid JSON. Nothing else.
    """

    // Used when converting pasted HTML from a learning website
    private let htmlSystemPrompt = """
    You are an Indonesian language learning content creator for Korean speakers. \
    The user will paste text extracted from an Indonesian language learning website. \
    Extract the actual conversation dialogues, vocabulary, and grammar patterns from the content \
    and convert them into a structured learning package as a SINGLE JSON object.

    Output this exact JSON structure (no markdown, no extra text, ONLY JSON):
    {
      "title": "Topic in Bahasa Indonesia",
      "titleKo": "주제 (한국어)",
      "description": "한 줄 설명",
      "emoji": "single emoji",
      "difficulty": "Pemula",
      "rootNode": {
        "id": "xx_root",
        "speakerIsMe": true,
        "indonesian": "opening sentence extracted from content",
        "korean": "한국어 번역",
        "romanization": "한글 발음",
        "polarity": "neutral",
        "coachTipLabel": "Strategi Pembuka",
        "coachTipText": "explanation in Indonesian",
        "coachTipWhy": "reason in Indonesian",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": false,
            "indonesian": "...",
            "korean": "...",
            "romanization": "한글 발음",
            "polarity": "positive",
            "coachTipLabel": null,
            "coachTipText": null,
            "coachTipWhy": null,
            "children": [...]
          }
        ]
      },
      "vocabulary": [
        { "indonesian": "word", "romanization": "한글 발음", "korean": "뜻", "category": "동사" }
      ],
      "grammarPoints": [
        {
          "number": 1,
          "titleId": "Pattern name",
          "titleKo": "패턴 이름",
          "explanation": "한국어로 설명",
          "examples": [{ "indonesian": "example", "korean": "한국어" }]
        }
      ]
    }

    Rules:
    - Extract REAL dialogue lines from the source content — do not invent new sentences
    - Organize extracted dialogues into a branching tree (2–3 branches showing different situations)
    - difficulty: "Pemula", "Menengah", or "Mahir" based on content complexity
    - Node IDs: short + letter/number (e.g. "mk_root", "mk_a", "mk_a1")
    - Strictly alternate speakers: speakerIsMe:true → children all false, and vice versa
    - polarity: "positive" = good move, "negative" = realistic but less ideal, "neutral" = opener
    - coachTip: provide for key strategy nodes, null for simple response nodes
    - romanization: Korean phonetics ONLY (한글), e.g. "아빠까 이니 쁘다스?" NOT Latin
    - vocabulary: extract ALL non-trivial words that appear in the source content
    - grammarPoints: 3–5 key grammar patterns found in the source content
    - Output ONLY valid JSON. Nothing else.
    """

    // MARK: - Public API

    func generate(prompt: String, apiKey: String) async throws -> AIScenario {
        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 8000,
            "system": topicSystemPrompt,
            "messages": [["role": "user", "content": "Generate a scenario for: \(prompt)"]]
        ]
        return try await sendRequest(body: body, apiKey: apiKey, userPrompt: prompt)
    }

    func generateFromHTML(html: String, apiKey: String) async throws -> AIScenario {
        let stripped = stripHTML(html)
        let truncated = String(stripped.prefix(12000))
        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 8000,
            "system": htmlSystemPrompt,
            "messages": [["role": "user", "content": "Convert this Indonesian learning content:\n\n\(truncated)"]]
        ]
        return try await sendRequest(body: body, apiKey: apiKey, userPrompt: "HTML 콘텐츠")
    }

    // MARK: - Private

    private func sendRequest(body: [String: Any], apiKey: String, userPrompt: String) async throws -> AIScenario {
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
            return raw.toAIScenario(userPrompt: userPrompt)
        } catch {
            throw ClaudeError.invalidJSON("\(error): \(jsonText.prefix(300))")
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
