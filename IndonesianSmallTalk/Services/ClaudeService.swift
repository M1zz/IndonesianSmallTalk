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
        "speakerIsMe": false,
        "indonesian": "opening sentence (other speaker starts)",
        "korean": "한국어 번역",
        "romanization": "한글 발음",
        "polarity": "neutral",
        "coachTipLabel": "Strategi Pembuka",
        "coachTipText": "explanation in Indonesian",
        "coachTipWhy": "reason in Indonesian",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": true,
            "indonesian": "my positive reply",
            "korean": "...",
            "romanization": "한글 발음",
            "polarity": "positive",
            "coachTipLabel": "Teknik",
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

    TREE DEPTH RULES — follow exactly:
    - Root node is always the OTHER speaker (speakerIsMe: false) opening the conversation
    - Root must have 2–3 children (speakerIsMe: true) representing different ways I can respond
    - Each path must be EXACTLY 5 nodes deep from root (root=depth0, leaf=depth4):
        depth 0: root (other) → depth 1: my reply (me) → depth 2: their follow-up (other) → depth 3: my response (me) → depth 4: their closing (other, children:[])
    - At depth 1: 2–3 branches (positive / neutral / negative replies)
    - At depth 3: 2 branches under at least one depth-2 node (showing choice at that point)
    - Total nodes: 20–35
    - Strictly alternate speakers every level: speakerIsMe flips at every depth
    - difficulty: "Pemula", "Menengah", or "Mahir"
    - Node IDs: short prefix + letter/number (e.g. "rs_root", "rs_a", "rs_a1", "rs_a1a", "rs_a1a1")
    - polarity: "positive" = good/ideal, "negative" = awkward/less ideal, "neutral" = opener/factual
    - coachTip: provide for depth-1 nodes (my first replies) and 1–2 key strategy nodes; null elsewhere
    - romanization: Korean phonetics ONLY (한글), e.g. "시아빠 까바르?" NOT Latin romanization
    - vocabulary: 15–20 items covering key words in the tree
    - grammarPoints: 3–4 key grammar patterns
    - Output ONLY valid JSON. No markdown, no explanation, no extra text.
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
        "speakerIsMe": false,
        "indonesian": "opening sentence from content",
        "korean": "한국어 번역",
        "romanization": "한글 발음",
        "polarity": "neutral",
        "coachTipLabel": "Strategi Pembuka",
        "coachTipText": "explanation in Indonesian",
        "coachTipWhy": "reason in Indonesian",
        "children": [
          {
            "id": "xx_a",
            "speakerIsMe": true,
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

    TREE DEPTH RULES — follow exactly:
    - Root node is the OTHER speaker (speakerIsMe: false) — use real opening line from source
    - Root must have 2–3 children (speakerIsMe: true) representing different response approaches
    - Each path must be EXACTLY 5 nodes deep (root=depth0 to leaf=depth4):
        depth 0: root (other) → depth 1: my reply (me) → depth 2: their follow-up (other) → depth 3: my response (me) → depth 4: their closing (other, children:[])
    - At depth 1: 2–3 branches; at depth 3: 2 branches under at least one depth-2 node
    - Total nodes: 20–35
    - Strictly alternate speakers: speakerIsMe flips at every depth
    - Extract REAL dialogue lines from source — do not invent sentences not found in the content
    - difficulty: "Pemula", "Menengah", or "Mahir" based on content complexity
    - Node IDs: short prefix + letter/number (e.g. "mk_root", "mk_a", "mk_a1", "mk_a1a", "mk_a1a1")
    - polarity: "positive" = good/ideal, "negative" = awkward/less ideal, "neutral" = opener/factual
    - coachTip: provide for depth-1 nodes and 1–2 key strategy nodes; null elsewhere
    - romanization: Korean phonetics ONLY (한글), NOT Latin romanization
    - vocabulary: 15–20 items from source content
    - grammarPoints: 3–4 key grammar patterns
    - Output ONLY valid JSON. No markdown, no explanation.
    """

    // MARK: - Public API

    func generate(prompt: String, apiKey: String) async throws -> AIScenario {
        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 16000,
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
            "max_tokens": 16000,
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
        } catch let decodeError as DecodingError {
            // Surface the exact field that failed so we can debug prompt issues
            let context: String
            switch decodeError {
            case .keyNotFound(let key, _):
                context = "필드 누락: '\(key.stringValue)'"
            case .typeMismatch(_, let ctx):
                context = "타입 불일치: \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
            case .valueNotFound(_, let ctx):
                context = "값 없음: \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
            case .dataCorrupted(let ctx):
                context = "데이터 손상: \(ctx.debugDescription)"
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
