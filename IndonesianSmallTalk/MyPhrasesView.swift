import SwiftUI

struct MyPhrasesView: View {
    @EnvironmentObject var store: PhraseStore
    @StateObject private var speech = SpeechManager()
    @State private var practicing: MyPhrase?
    @State private var editing: MyPhrase?

    var body: some View {
        Group {
            if store.phrases.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.phrases) { phrase in
                        PhraseRow(
                            phrase: phrase,
                            isSpeaking: speech.isSpeaking,
                            onPlay: { speech.speak(phrase.indonesian) },
                            onPractice: { practicing = phrase },
                            onEdit: { editing = phrase }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                store.delete(id: phrase.id)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                            Button {
                                editing = phrase
                            } label: {
                                Label("수정", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("내 표현")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $practicing) { phrase in
            PhrasePracticeView(phrase: phrase)
        }
        .sheet(item: $editing) { phrase in
            AddPhraseView(editing: phrase)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("아직 저장한 표현이 없어요")
                .font(.headline)
            Text("스몰토크 중 새로 배운 표현을\n+ 버튼으로 바로 기록해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct PhraseRow: View {
    let phrase: MyPhrase
    let isSpeaking: Bool
    let onPlay: () -> Void
    let onPractice: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(phrase.indonesian)
                            .font(.system(size: 16, weight: .semibold))
                        PolarityChip(polarity: phrase.polarity)
                    }
                    Text(phrase.korean)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onPlay) {
                    Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            if !phrase.context.isEmpty {
                Text(phrase.context)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.top, 2)
            }
            HStack(spacing: 8) {
                Button(action: onPractice) {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                        Text("따라말하기")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("수정")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

struct PolarityChip: View {
    let polarity: Polarity

    var body: some View {
        if polarity != .neutral {
            HStack(spacing: 2) {
                Text(polarity == .positive ? "+" : "−")
                    .font(.system(size: 11, weight: .black))
                Text(polarity == .positive ? "긍정" : "부정")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(polarity == .positive ? Color(red: 0.2, green: 0.55, blue: 0.1) : Color(red: 0.85, green: 0.4, blue: 0.0))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(polarity == .positive ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
            )
        }
    }
}

struct PhrasePracticeView: View {
    let phrase: MyPhrase
    @EnvironmentObject var store: PhraseStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechManager()
    @State private var score: Double?
    @State private var permissionAsked = false
    @State private var didCount = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(phrase.indonesian)
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(phrase.korean)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                Button(action: { speech.speak(phrase.indonesian) }) {
                    Label("듣기", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Spacer()

                if !speech.recognizedText.isEmpty {
                    VStack(spacing: 6) {
                        Text("내 발음")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(speech.recognizedText)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                if let score {
                    scoreBadge(score: score)
                }

                Button(action: toggleListen) {
                    ZStack {
                        Circle()
                            .fill(speech.isListening ? Color.red : Color.blue)
                            .frame(width: 76, height: 76)
                        Image(systemName: speech.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!speech.permissionGranted && permissionAsked)

                Text(speech.isListening ? "듣는 중…" : "버튼을 눌러 따라 말해보세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .navigationTitle("연습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                if !permissionAsked {
                    permissionAsked = true
                    await speech.requestPermissions()
                }
            }
        }
    }

    private func toggleListen() {
        if speech.isListening {
            speech.stopListening()
            evaluate()
            return
        }
        score = nil
        do {
            try speech.startListening { [self] in
                Task { @MainActor in
                    self.evaluate()
                }
            }
        } catch {
            print("Listen start failed: \(error)")
        }
    }

    private func evaluate() {
        guard !speech.recognizedText.isEmpty else { return }
        let s = SpeechManager.similarityScore(
            spoken: speech.recognizedText,
            target: phrase.indonesian
        )
        score = s
        // 충분히 잘 따라말한 경우만 카운트, 한 세션당 1회만
        if !didCount && s >= 0.5 {
            didCount = true
            store.incrementStudyCount(id: phrase.id)
        }
    }

    private func scoreBadge(score: Double) -> some View {
        let percent = Int((score * 100).rounded())
        let (label, color): (String, Color) = {
            switch percent {
            case 80...: return ("아주 좋아요!", .green)
            case 50..<80: return ("좋아요", .blue)
            case 20..<50: return ("조금만 더", .orange)
            default: return ("다시 해볼까요?", .red)
            }
        }()
        return HStack(spacing: 8) {
            Text("\(percent)%")
                .font(.system(size: 18, weight: .bold))
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(10)
    }
}
