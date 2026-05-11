import SwiftUI

// MARK: - Vocabulary List

struct VocabularyView: View {
    @EnvironmentObject var store: VocabularyStore
    @StateObject private var speech = SpeechManager()
    let onAdd: () -> Void
    let onEdit: (VocabWord) -> Void

    @State private var unlearnedOnly = false
    @State private var speakingId: UUID?

    private var displayed: [VocabWord] {
        unlearnedOnly ? store.unlearnedWords : store.words
    }

    var body: some View {
        if store.words.isEmpty {
            emptyState
        } else {
            List {
                Section {
                    Toggle(isOn: $unlearnedOnly) {
                        Label("미학습만 보기", systemImage: "graduationcap.fill")
                            .font(.system(size: 14))
                    }
                    .tint(.blue)
                }

                Section {
                    if displayed.isEmpty {
                        Text("모든 단어를 학습 완료했어요 🎉")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(displayed) { word in
                            WordRow(
                                word: word,
                                isSpeakingThis: speakingId == word.id && speech.isSpeaking,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3)) {
                                        store.toggleLearned(id: word.id)
                                    }
                                },
                                onSpeak: { speakWord(word) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    store.delete(id: word.id)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                Button { onEdit(word) } label: {
                                    Label("수정", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        store.toggleLearned(id: word.id)
                                    }
                                } label: {
                                    Label(word.isLearned ? "미학습" : "완료",
                                          systemImage: word.isLearned ? "minus.circle" : "checkmark.circle")
                                }
                                .tint(word.isLearned ? .orange : .green)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("전체 \(store.words.count)개")
                        Spacer()
                        Text("완료 \(store.learnedWords.count)개")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .onDisappear { speech.stopSpeaking() }
        }
    }

    private func speakWord(_ word: VocabWord) {
        speakingId = word.id
        speech.speak(word.indonesian) {
            Task { @MainActor in
                if speakingId == word.id { speakingId = nil }
            }
        }
        store.incrementStudy(id: word.id)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            Text("단어장이 비어있어요")
                .font(.headline)
            Text("모르는 단어를 추가해서\n플래시카드로 학습해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Label("단어 추가하기", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Word Row

struct WordRow: View {
    let word: VocabWord
    var isSpeakingThis: Bool = false
    let onToggle: () -> Void
    var onSpeak: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: word.isLearned ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(word.isLearned ? .green : Color(.tertiaryLabel))
                    .animation(.spring(response: 0.3), value: word.isLearned)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(word.indonesian)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(word.isLearned ? .secondary : .primary)
                        .strikethrough(word.isLearned)
                        .lineLimit(1)
                    TierBadge(tier: word.tier)
                    CategoryBadge(category: word.category)
                }
                if !word.romanization.isEmpty {
                    Text(word.romanization)
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundColor(Color(.tertiaryLabel))
                        .lineLimit(1)
                }
                Text(word.korean)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if !word.examples.isEmpty {
                        Label("\(word.examples.count)", systemImage: "text.bubble")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    if !word.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let onSpeak {
                    Button(action: onSpeak) {
                        Image(systemName: isSpeakingThis ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 18))
                            .foregroundColor(isSpeakingThis ? .blue : .blue.opacity(0.7))
                            .symbolEffect(.bounce, value: isSpeakingThis)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(Color.blue.opacity(isSpeakingThis ? 0.18 : 0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
                if word.studyCount > 0 {
                    Text("\(word.studyCount)회")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: String

    static func color(for category: String) -> Color {
        switch category {
        case "인사·호칭":         return .pink
        case "긍정·부정·확인":    return .green
        case "부탁·사과·감사":    return .orange
        case "의문사":            return .purple
        case "동사·조동사":       return .blue
        case "숫자·가격":         return Color(red: 0.78, green: 0.56, blue: 0.0) // amber
        case "식당·음식":         return .red
        case "교통":              return .teal
        case "장소·방향":         return .indigo
        case "시간":              return Color(red: 0.55, green: 0.40, blue: 0.30) // brown
        case "호텔·비즈니스":     return .gray
        case "정도·상태":         return .cyan
        case "추임새·접속사":     return .mint
        default:                  return .gray
        }
    }

    var body: some View {
        let c = Self.color(for: category)
        Text(category)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(c)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(c.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Formality Badge (F/N/C/S)

struct FormalityBadge: View {
    let level: FormalityLevel

    static func color(for level: FormalityLevel) -> Color {
        switch level {
        case .formal:  return Color(red: 0.12, green: 0.23, blue: 0.37) // 깊은 남색
        case .neutral: return Color(red: 0.36, green: 0.42, blue: 0.24) // 올리브
        case .casual:  return Color(red: 0.72, green: 0.36, blue: 0.18) // 테라코타
        case .slang:   return Color(red: 0.55, green: 0.16, blue: 0.09) // 적토
        }
    }

    var body: some View {
        let c = Self.color(for: level)
        Text(level.rawValue)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: 16, height: 16)
            .background(Circle().fill(c))
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: Int

    private var label: String {
        switch tier {
        case 1: return "필수"
        case 2: return "편의"
        case 3: return "심화"
        default: return "—"
        }
    }

    private var color: Color {
        switch tier {
        case 1: return .red
        case 2: return .blue
        case 3: return .gray
        default: return .secondary
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Flashcard View

struct FlashcardView: View {
    let words: [VocabWord]
    @EnvironmentObject var store: VocabularyStore
    @StateObject private var speech = SpeechManager()
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var knownCount = 0
    @State private var retryCount = 0
    @State private var showCompletion = false
    @AppStorage("flashcardAutoSpeak") private var autoSpeak = true

    private var current: VocabWord? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if showCompletion {
                    completionView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else if let word = current {
                    VStack(spacing: 0) {
                        progressBar.padding(.horizontal, 20).padding(.top, 12)

                        Spacer()

                        // Card with slide transition between words
                        ZStack {
                            cardFront(word: word)
                                .rotation3DEffect(
                                    .degrees(isFlipped ? 90 : 0),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.5
                                )
                                .opacity(isFlipped ? 0 : 1)

                            cardBack(word: word)
                                .rotation3DEffect(
                                    .degrees(isFlipped ? 0 : -90),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.5
                                )
                                .opacity(isFlipped ? 1 : 0)
                        }
                        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: isFlipped)
                        .padding(.horizontal, 24)
                        .id(currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .onTapGesture {
                            withAnimation { isFlipped.toggle() }
                        }

                        Text(isFlipped ? "알고 있나요?" : "탭하면 뜻이 나와요")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.tertiaryLabel))
                            .padding(.top, 16)

                        Spacer()

                        // Buttons — appear after flip
                        actionButtons(word: word)
                            .opacity(isFlipped ? 1 : 0)
                            .animation(.spring(response: 0.3), value: isFlipped)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("플래시카드")
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
            .onAppear {
                if autoSpeak, let first = current {
                    speakWord(first)
                }
            }
            .onDisappear { speech.stopSpeaking() }
        }
    }

    private func speakWord(_ word: VocabWord) {
        speech.speak(word.indonesian)
    }

    private func speakExample(_ ex: VocabExample) {
        speech.speak(ex.indonesian)
    }

    // MARK: Progress

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(min(currentIndex + 1, words.count)) / \(words.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 10) {
                    Label("\(knownCount)", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    Label("\(retryCount)", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(currentIndex) / CGFloat(max(words.count, 1)), height: 5)
                        .animation(.spring(response: 0.4), value: currentIndex)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: Card Faces

    private func cardFront(word: VocabWord) -> some View {
        VStack(spacing: 16) {
            CategoryBadge(category: word.category)
                .scaleEffect(1.2)
            Text(word.indonesian)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
            if !word.romanization.isEmpty {
                Text(word.romanization)
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)
            }

            // 발음 듣기 버튼 — 카드 탭(뒤집기)와 충돌 안 나게 별도 버튼
            Button {
                speakWord(word)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2.fill")
                        .symbolEffect(.bounce, value: speech.isSpeaking)
                    Text("듣기")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Text("탭해서 뒤집기")
                .font(.system(size: 11))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 5)
        )
    }

    private func cardBack(word: VocabWord) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue.opacity(0.4))
                Text(word.korean)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(word.indonesian)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                if !word.notes.isEmpty {
                    Text(word.notes)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                if !word.examples.isEmpty {
                    Divider().padding(.vertical, 2)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("예문")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        ForEach(Array(word.examples.enumerated()), id: \.offset) { idx, ex in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("\(idx + 1).")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue.opacity(0.6))
                                    Text(ex.indonesian)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    if let level = ex.level {
                                        FormalityBadge(level: level)
                                    }
                                    Spacer(minLength: 4)
                                    Button {
                                        speakExample(ex)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.blue)
                                            .frame(width: 26, height: 26)
                                            .background(Circle().fill(Color.blue.opacity(0.12)))
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(ex.korean)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 18)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 2)
                }

                if word.studyCount > 0 {
                    Text("학습 \(word.studyCount)회")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .frame(minHeight: 220, maxHeight: 380)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.blue.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color.blue.opacity(0.08), radius: 14, x: 0, y: 5)
        )
    }

    // MARK: Action Buttons

    private func actionButtons(word: VocabWord) -> some View {
        HStack(spacing: 16) {
            Button {
                retryCount += 1
                advance(word: word, known: false)
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .semibold))
                    Text("다시")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                knownCount += 1
                advance(word: word, known: true)
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .semibold))
                    Text("알아요!")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Logic

    private func advance(word: VocabWord, known: Bool) {
        store.incrementStudy(id: word.id)
        if known && !word.isLearned {
            store.toggleLearned(id: word.id)
        }
        speech.stopSpeaking()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isFlipped = false
            if currentIndex + 1 >= words.count {
                showCompletion = true
            } else {
                currentIndex += 1
            }
        }
        // 다음 카드로 넘어갔으면 그 단어를 자동 발음
        if autoSpeak, !showCompletion, currentIndex < words.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if let next = current { speakWord(next) }
            }
        }
    }

    // MARK: Completion

    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Text(knownCount == words.count ? "🎉" : knownCount > words.count / 2 ? "⭐" : "💪")
                    .font(.system(size: 64))
                Text(knownCount == words.count ? "완벽해요!" : "잘했어요!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("총 \(words.count)개 중 \(knownCount)개를 알았어요")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FlashcardResultCard(icon: "checkmark.circle.fill",
                                    value: "\(knownCount)개",
                                    label: "알았어요",
                                    color: .green)
                FlashcardResultCard(icon: "arrow.clockwise",
                                    value: "\(retryCount)개",
                                    label: "다시 학습",
                                    color: .orange)
            }
            .padding(.horizontal, 28)

            Spacer()

            Button("닫기") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
        }
    }
}

private struct FlashcardResultCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
