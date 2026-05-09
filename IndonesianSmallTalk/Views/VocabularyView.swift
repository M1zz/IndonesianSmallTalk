import SwiftUI

// MARK: - Vocabulary List

struct VocabularyView: View {
    @EnvironmentObject var store: VocabularyStore
    let onAdd: () -> Void
    let onEdit: (VocabWord) -> Void

    @State private var unlearnedOnly = false

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
                            WordRow(word: word) {
                                withAnimation(.spring(response: 0.3)) {
                                    store.toggleLearned(id: word.id)
                                }
                            }
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
        }
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
    let onToggle: () -> Void

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
                    CategoryBadge(category: word.category)
                }
                if !word.romanization.isEmpty {
                    Text(word.romanization)
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundColor(Color(.tertiaryLabel))
                }
                Text(word.korean)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if !word.notes.isEmpty {
                    Text(word.notes)
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                        .lineLimit(1)
                }
            }

            Spacer()

            if word.studyCount > 0 {
                Text("\(word.studyCount)회")
                    .font(.system(size: 10))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: String

    private var color: Color {
        switch category {
        case "명사":   return .blue
        case "동사":   return .orange
        case "형용사": return .green
        case "부사":   return .purple
        case "숙어":   return .pink
        default:       return .gray
        }
    }

    var body: some View {
        Text(category)
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
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var knownCount = 0
    @State private var retryCount = 0
    @State private var showCompletion = false

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
            }
        }
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
            Text("탭해서 뒤집기")
                .font(.system(size: 11))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 8)
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
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundColor(.blue.opacity(0.4))
            Text(word.korean)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            if !word.notes.isEmpty {
                Text(word.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if word.studyCount > 0 {
                Text("학습 \(word.studyCount)회")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .padding(28)
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
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isFlipped = false
            if currentIndex + 1 >= words.count {
                showCompletion = true
            } else {
                currentIndex += 1
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
