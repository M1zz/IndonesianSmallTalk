import SwiftUI

/// 단어장 예문을 대화 흐름으로 학습하는 뷰.
/// 한 단어의 예문들을 채팅 버블처럼 차례로 노출하며 TTS 자동 재생.
/// 격식(F)은 왼쪽=상대방, 캐주얼(C)은 오른쪽=나로 정렬되어 시각적으로 회화 톤을 익힘.
struct VocabDialogView: View {
    let words: [VocabWord]
    @EnvironmentObject var store: VocabularyStore
    @StateObject private var speech = SpeechManager()
    @Environment(\.dismiss) private var dismiss

    @State private var currentWordIndex = 0
    @State private var visibleExampleCount = 0
    @State private var revealedTranslations: Set<Int> = []
    @State private var speakingExampleIndex: Int?
    @AppStorage("vocabDialogAutoSpeak") private var autoSpeak = true

    private var currentWord: VocabWord? {
        guard currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    private var atLastWord: Bool { currentWordIndex >= words.count - 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if let word = currentWord {
                    VStack(spacing: 0) {
                        progressBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        wordHeader(word: word)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 14) {
                                    ForEach(0..<visibleExampleCount, id: \.self) { idx in
                                        if idx < word.examples.count {
                                            dialogBubble(
                                                example: word.examples[idx],
                                                index: idx,
                                                isSpeaking: speakingExampleIndex == idx,
                                                isLast: idx == visibleExampleCount - 1
                                            )
                                            .id(idx)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                        }
                                    }

                                    if visibleExampleCount == 0 {
                                        emptyHint
                                    }

                                    if visibleExampleCount >= word.examples.count && !word.examples.isEmpty {
                                        wordFooter(word: word)
                                            .padding(.top, 8)
                                    }

                                    Color.clear.frame(height: 60).id("bottom")
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }
                            .onChange(of: visibleExampleCount) { _, _ in
                                withAnimation(.spring(response: 0.4)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }

                        actionBar(word: word)
                    }
                } else {
                    completionView
                }
            }
            .navigationTitle("회화 모드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        autoSpeak.toggle()
                        if !autoSpeak { speech.stopSpeaking() }
                    } label: {
                        Image(systemName: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(autoSpeak ? .blue : Color(.tertiaryLabel))
                    }
                }
            }
            .onDisappear { speech.stopSpeaking() }
        }
    }

    // MARK: Progress

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(min(currentWordIndex + 1, words.count)) / \(words.count) 단어")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if let w = currentWord, !w.examples.isEmpty {
                    Text("예문 \(min(visibleExampleCount, w.examples.count))/\(w.examples.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(currentWordIndex) / CGFloat(max(words.count, 1)), height: 5)
                        .animation(.spring(response: 0.4), value: currentWordIndex)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: Word Header

    private func wordHeader(word: VocabWord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    CategoryBadge(category: word.category)
                    TierBadge(tier: word.tier)
                }
                Text(word.indonesian)
                    .font(.system(size: 22, weight: .bold))
                if !word.romanization.isEmpty {
                    Text(word.romanization)
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundColor(.secondary)
                }
                Text(word.korean)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                if !word.notes.isEmpty {
                    Text(word.notes)
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.top, 2)
                }
            }
            Spacer()
            Button {
                speech.speak(word.indonesian)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }

    // MARK: Bubble

    private func dialogBubble(example: VocabExample, index: Int, isSpeaking: Bool, isLast: Bool) -> some View {
        let level = example.level ?? .neutral
        let bubbleColor = FormalityBadge.color(for: level)
        let isCasual = (level == .casual || level == .slang)
        // 격식·중립 → 왼쪽 (상대방/공식), 캐주얼·슬랭 → 오른쪽 (나/친구)
        let speakerLabel = isCasual ? "나" : (level == .formal ? "상대방·격식" : "예시")

        return HStack(alignment: .top, spacing: 8) {
            if isCasual { Spacer(minLength: 40) }

            VStack(alignment: isCasual ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let l = example.level {
                        FormalityBadge(level: l)
                    }
                    Text(speakerLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(example.indonesian)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    if revealedTranslations.contains(index) {
                        Divider().padding(.vertical, 2)
                        Text(example.korean)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(bubbleColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(bubbleColor.opacity(isLast ? 0.6 : 0.25),
                                              lineWidth: isLast ? 1.5 : 0.8)
                        )
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        if revealedTranslations.contains(index) {
                            revealedTranslations.remove(index)
                        } else {
                            revealedTranslations.insert(index)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        speakExample(example, at: index)
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isSpeaking ? bubbleColor : bubbleColor.opacity(0.7))
                            .symbolEffect(.bounce, value: isSpeaking)
                    }
                    .buttonStyle(.plain)

                    Text(revealedTranslations.contains(index) ? "탭하면 번역 숨김" : "탭하면 한국어 번역")
                        .font(.system(size: 9))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            if !isCasual { Spacer(minLength: 40) }
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32))
                .foregroundColor(Color(.tertiaryLabel))
            Text("아래 '다음 예문' 버튼을 눌러 시작하세요")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func wordFooter(word: VocabWord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("이 단어의 예문 \(word.examples.count)개를 다 봤어요")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.08))
        )
    }

    // MARK: Action Bar

    private func actionBar(word: VocabWord) -> some View {
        HStack(spacing: 12) {
            if visibleExampleCount < word.examples.count {
                Button(action: revealNextExample) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                        Text(visibleExampleCount == 0 ? "첫 예문 보기" : "다음 예문")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: advanceToNextWord) {
                    HStack {
                        Text(atLastWord ? "학습 완료" : "다음 단어")
                            .fontWeight(.semibold)
                        Image(systemName: atLastWord ? "checkmark" : "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(atLastWord ? Color.green : Color.blue,
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
        )
    }

    // MARK: Completion

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("완료!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("\(words.count)개 단어 · 예문 \(words.reduce(0) { $0 + $1.examples.count })개를 둘러봤어요")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Button("닫기") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
        }
    }

    // MARK: Logic

    private func revealNextExample() {
        guard let word = currentWord, visibleExampleCount < word.examples.count else { return }
        let newIndex = visibleExampleCount
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            visibleExampleCount += 1
        }
        if autoSpeak, newIndex < word.examples.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                speakExample(word.examples[newIndex], at: newIndex)
            }
        }
    }

    private func advanceToNextWord() {
        guard let word = currentWord else { return }
        store.incrementStudy(id: word.id)
        speech.stopSpeaking()
        withAnimation(.spring(response: 0.4)) {
            if atLastWord {
                currentWordIndex = words.count
            } else {
                currentWordIndex += 1
                visibleExampleCount = 0
                revealedTranslations.removeAll()
            }
        }
    }

    private func speakExample(_ ex: VocabExample, at index: Int) {
        speakingExampleIndex = index
        speech.speak(ex.indonesian) {
            Task { @MainActor in
                if speakingExampleIndex == index { speakingExampleIndex = nil }
            }
        }
    }
}
