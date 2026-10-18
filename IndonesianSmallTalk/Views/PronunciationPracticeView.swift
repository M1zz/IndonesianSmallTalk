import SwiftUI

// MARK: - Sentence

/// 발음 연습에 쓰는 문장 하나
struct PracticeSentence: Identifiable, Hashable {
    let id: String
    let text: String
    let meaning: String
    var romanization: String = ""

    /// 시나리오 트리에서 내가 말하는 문장만 모은다 (같은 문장은 한 번만)
    static func lines(of scenario: ConversationScenario) -> [PracticeSentence] {
        var seen = Set<String>()
        var result: [PracticeSentence] = []
        func walk(_ node: ConversationNode) {
            if node.speaker == .me, seen.insert(node.text).inserted {
                result.append(PracticeSentence(id: node.id, text: node.text, meaning: node.meaning,
                                               romanization: node.displayRomanization))
            }
            node.children.forEach(walk)
        }
        walk(scenario.root)
        return result
    }

    static func from(_ phrase: MyPhrase) -> PracticeSentence {
        PracticeSentence(id: "phrase-\(phrase.id.uuidString)", text: phrase.text, meaning: phrase.meaning)
    }
}

// MARK: - Pronunciation Practice

/// 발음 연습: 듣기 → 따라 말하기 → 점수와 낱말(일본어·중국어는 글자)별 맞은 곳/틀린 곳.
/// sentences 를 넘기면 그 문장들로(예: 시나리오에서 열 때), 비우면 기본 회화·내 표현에서 고른다.
struct PronunciationPracticeView: View {
    @EnvironmentObject var phraseStore: PhraseStore
    @StateObject private var speech = SpeechManager()

    private let initialSentences: [PracticeSentence]?
    private let sessionTitle: String?
    private let sessionTitleMeaning: String
    private let scenarioKey: String

    enum Source: String, CaseIterable, Identifiable {
        case library, myPhrases
        var id: String { rawValue }
        var label: String {
            self == .library ? String(localized: "추천 문장") : String(localized: "내 표현")
        }
    }

    private enum Phase { case ready, recording, result }

    @State private var source: Source = .library
    @State private var sentences: [PracticeSentence] = []
    @State private var index = 0
    @State private var phase: Phase = .ready
    @State private var score: Int?
    @State private var showMeaning = true
    @State private var showPermissionAlert = false
    @State private var startError: String?
    /// 문장 id → 가장 좋은 점수 (기록할 때 평균을 낸다)
    @State private var bestScores: [String: Int] = [:]
    @State private var recorded = false

    /// 한 번에 연습할 추천 문장 수
    private let libraryCount = 10

    init(sentences: [PracticeSentence]? = nil, title: String? = nil,
         titleMeaning: String = "", scenarioKey: String = "") {
        self.initialSentences = sentences.flatMap { $0.isEmpty ? nil : $0 }
        self.sessionTitle = title
        self.sessionTitleMeaning = titleMeaning
        self.scenarioKey = scenarioKey
    }

    /// 시나리오에서 바로 열 때
    init(scenario: ConversationScenario) {
        self.init(sentences: PracticeSentence.lines(of: scenario), title: scenario.title,
                  titleMeaning: scenario.titleKo, scenarioKey: scenario.key)
    }

    private var current: PracticeSentence? { sentences.indices.contains(index) ? sentences[index] : nil }
    private var language: AppLanguage { AppLanguage.learning }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    if initialSentences == nil {
                        Picker(selection: $source) {
                            ForEach(Source.allCases) { Text($0.label).tag($0) }
                        } label: { Text("문장 고르기") }
                        .pickerStyle(.segmented)
                        .onChange(of: source) { _, _ in reload() }
                    }

                    if let current {
                        progressHeader
                        sentenceCard(current)
                        if phase == .recording || (phase == .result && !speech.recognizedText.isEmpty) {
                            heardCard
                        }
                        if phase == .result { resultCard(current) }
                    } else {
                        emptyState
                    }
                }
                .padding(18)
            }

            if current != nil {
                Divider()
                controls
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                    .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("발음 연습"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showMeaning.toggle() } label: {
                    Image(systemName: showMeaning ? "eye" : "eye.slash")
                }
                .accessibilityLabel(showMeaning ? Text("뜻 숨기기") : Text("뜻 보이기"))
            }
        }
        .onAppear { if sentences.isEmpty { reload() } }
        .onDisappear {
            speech.stopListening()
            speech.stopSpeaking()
            recordSession()
        }
        .onChange(of: speech.isListening) { _, listening in
            // 정적 감지·인식 끝·직접 멈춤 모두 여기서 채점
            if !listening && phase == .recording { evaluate() }
        }
        .alert(Text("마이크를 쓸 수 없어요"), isPresented: $showPermissionAlert) {
            Button(String(localized: "설정 열기")) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button(String(localized: "닫기"), role: .cancel) {}
        } message: {
            Text("발음을 들으려면 설정에서 마이크와 음성 인식을 허용해 주세요. 듣기는 지금도 할 수 있어요.")
        }
    }

    // MARK: - Sections

    private var progressHeader: some View {
        HStack {
            Text("\(index + 1) / \(sentences.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
            if initialSentences == nil && source == .library {
                Button { reload() } label: {
                    Label(String(localized: "다른 문장"), systemImage: "shuffle")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
        }
    }

    private func sentenceCard(_ s: PracticeSentence) -> some View {
        VStack(spacing: 12) {
            Text(s.text)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if !s.romanization.isEmpty {
                Text(s.romanization)
                    .font(.system(size: 13))
                    .foregroundColor(Brand.blue)
            }
            if showMeaning && !s.meaning.isEmpty {
                Text(s.meaning)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button { listen(s) } label: {
                Label(speech.isSpeaking ? String(localized: "듣는 중…") : String(localized: "들어 보기"),
                      systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Brand.blue.opacity(0.12)))
                    .foregroundColor(Brand.blue)
            }
            .disabled(phase == .recording)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }

    private var heardCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("들린 말")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Text(speech.recognizedText.isEmpty ? String(localized: "듣고 있어요…") : speech.recognizedText)
                .font(.system(size: 15))
                .foregroundColor(speech.recognizedText.isEmpty ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }

    @ViewBuilder
    private func resultCard(_ s: PracticeSentence) -> some View {
        VStack(spacing: 12) {
            if let score {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(score))
                    Text("점")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                Text(scoreComment(score))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(scoreColor(score))

                VStack(alignment: .leading, spacing: 6) {
                    Text(language.writesWithoutSpaces ? "글자별로 보기" : "낱말별로 보기")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(highlighted(target: s.text, spoken: speech.recognizedText))
                        .font(.system(size: 19, weight: .semibold))
                    HStack(spacing: 12) {
                        legend(color: .green, text: Text("맞게 들림"))
                        legend(color: .red, text: Text("놓친 부분"))
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Image(systemName: "ear.trianglebadge.exclamationmark")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
                Text("잘 들리지 않았어요. 조금 더 크게 다시 말해 볼까요?")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let startError {
                Text(startError).font(.system(size: 12)).foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func legend(color: Color, text: Text) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            text.font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 38))
                .foregroundColor(Brand.blue.opacity(0.6))
            Text(source == .myPhrases ? "아직 내 표현이 없어요" : "연습할 문장이 없어요")
                .font(.system(size: 16, weight: .semibold))
            Text(source == .myPhrases
                 ? "내 표현 탭에서 \(language.localizedName) 표현을 더하면 여기서 발음을 연습할 수 있어요."
                 : "\(language.localizedName) 기본 회화를 불러오지 못했어요.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if phase == .result {
                Button(action: retry) {
                    Label(String(localized: "다시 하기"), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                        .foregroundColor(.primary)
                }
                Button(action: next) {
                    Label(index + 1 < sentences.count ? String(localized: "다음 문장") : String(localized: "처음부터"),
                          systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Brand.solidBlue))
                        .foregroundColor(.white)
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(phase == .recording ? Color.red : Brand.blue)
                                .frame(width: 72, height: 72)
                                .shadow(color: (phase == .recording ? Color.red : Brand.blue).opacity(0.35), radius: 10, y: 4)
                            Image(systemName: phase == .recording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel(phase == .recording ? Text("녹음 멈추기") : Text("따라 말하기"))
                    .scaleEffect(phase == .recording ? 1.08 : 1)
                    .animation(.easeInOut(duration: 0.2), value: phase == .recording)
                    Text(phase == .recording ? "말이 끝나면 자동으로 채점해요" : "눌러서 따라 말해 보세요")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .font(.system(size: 15, weight: .semibold))
    }

    // MARK: - Actions

    private func reload() {
        speech.stopListening()
        if let initialSentences {
            sentences = initialSentences
        } else {
            switch source {
            case .myPhrases:
                sentences = phraseStore.phrases.map(PracticeSentence.from)
            case .library:
                let pool = ScenarioLibrary.all(for: language).flatMap(PracticeSentence.lines(of:))
                var seen = Set<String>()
                // 너무 긴 문장은 발음 연습에 맞지 않아 뺀다
                let unique = pool.filter { $0.text.count <= 60 && seen.insert($0.text).inserted }
                sentences = Array(unique.shuffled().prefix(libraryCount))
            }
        }
        index = 0
        resetAttempt()
    }

    private func listen(_ s: PracticeSentence) {
        speech.speak(s.text, language: language)
    }

    private func toggleRecording() {
        if phase == .recording {
            speech.stopListening()   // onChange 에서 채점
            return
        }
        Task {
            await speech.requestPermissions()
            guard speech.permissionGranted else {
                showPermissionAlert = true
                return
            }
            speech.stopSpeaking()
            startError = nil
            score = nil
            do {
                phase = .recording
                try speech.startListening()
            } catch {
                phase = .result
                startError = String(localized: "녹음을 시작하지 못했어요. 잠시 뒤 다시 해 주세요.")
            }
        }
    }

    private func evaluate() {
        guard let current else { return }
        let heard = speech.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if heard.isEmpty {
            score = nil
        } else {
            let value = Int((SpeechManager.similarityScore(spoken: heard, target: current.text) * 100).rounded())
            score = value
            bestScores[current.id] = max(bestScores[current.id] ?? 0, value)
        }
        phase = .result
    }

    private func retry() {
        resetAttempt()
    }

    private func next() {
        index = index + 1 < sentences.count ? index + 1 : 0
        resetAttempt()
    }

    private func resetAttempt() {
        phase = .ready
        score = nil
        startError = nil
        speech.recognizedText = ""
    }

    /// 화면을 닫을 때 한 번 기록 (한 문장이라도 채점됐을 때만)
    private func recordSession() {
        guard !recorded, !bestScores.isEmpty else { return }
        recorded = true
        let avg = bestScores.values.reduce(0, +) / bestScores.count
        PracticeHistoryStore.shared.record(
            language: language,
            scenarioKey: scenarioKey,
            title: sessionTitle ?? String(localized: "발음 연습"),
            titleMeaning: sessionTitleMeaning,
            mode: .pronunciation,
            score: avg,
            lines: bestScores.count
        )
    }

    // MARK: - Highlight

    /// 목표 문장을 낱말(또는 글자) 단위로 나눠 들린 것은 초록, 놓친 것은 빨강으로 칠한다.
    private func highlighted(target: String, spoken: String) -> AttributedString {
        let spokenNorm = SpeechManager.normalizeForMatch(spoken)
        var result = AttributedString()

        if language.writesWithoutSpaces {
            let heardChars = Set(spokenNorm.filter { $0 != " " })
            for ch in target {
                var piece = AttributedString(String(ch))
                let norm = SpeechManager.normalizeForMatch(String(ch))
                if norm.isEmpty {
                    piece.foregroundColor = .secondary   // 구두점·공백
                } else if heardChars.contains(Character(norm)) {
                    piece.foregroundColor = .green
                } else {
                    piece.foregroundColor = .red
                    piece.underlineStyle = .single
                }
                result += piece
            }
        } else {
            let heardWords = Set(spokenNorm.split(separator: " ").map(String.init))
            let words = target.split(separator: " ", omittingEmptySubsequences: true)
            for (i, word) in words.enumerated() {
                var piece = AttributedString(String(word))
                let norm = SpeechManager.normalizeForMatch(String(word))
                if norm.isEmpty {
                    piece.foregroundColor = .secondary
                } else if norm.split(separator: " ").allSatisfy({ heardWords.contains(String($0)) }) {
                    piece.foregroundColor = .green
                } else {
                    piece.foregroundColor = .red
                    piece.underlineStyle = .single
                }
                result += piece
                if i < words.count - 1 { result += AttributedString(" ") }
            }
        }
        return result
    }

    private func scoreColor(_ s: Int) -> Color {
        if s >= 80 { return .green }
        if s >= 50 { return .orange }
        return .red
    }

    private func scoreComment(_ s: Int) -> String {
        if s >= 90 { return String(localized: "완벽해요!") }
        if s >= 75 { return String(localized: "아주 좋아요!") }
        if s >= 50 { return String(localized: "거의 다 왔어요. 한 번 더!") }
        return String(localized: "천천히 들어 보고 다시 해 봐요.")
    }
}
