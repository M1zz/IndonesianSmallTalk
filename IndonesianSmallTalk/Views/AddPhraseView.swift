import SwiftUI

struct AddPhraseView: View {
    var editing: MyPhrase? = nil

    @EnvironmentObject var store: PhraseStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechManager()

    @State private var indonesian: String
    @State private var korean: String
    @State private var context: String
    @State private var polarity: Polarity
    @State private var inKeyboard: Bool
    @State private var permissionAsked = false

    init(editing: MyPhrase? = nil) {
        self.editing = editing
        _indonesian = State(initialValue: editing?.indonesian ?? "")
        _korean = State(initialValue: editing?.korean ?? "")
        _context = State(initialValue: editing?.context ?? "")
        _polarity = State(initialValue: editing?.polarity ?? .neutral)
        _inKeyboard = State(initialValue: editing?.inKeyboard ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EncouragementBanner(tone: .phrase)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section {
                    HStack(alignment: .top, spacing: 8) {
                        TextField(String(localized: "예: \(AppLanguage.learning.sampleGreeting)"), text: $indonesian, axis: .vertical)
                            .lineLimit(1...3)
                            .autocorrectionDisabled()
                        Button(action: toggleDictation) {
                            Image(systemName: speech.isListening ? "stop.circle.fill" : "mic.fill")
                                .scaledFont(size: 22)
                                .foregroundColor(speech.isListening ? .red : .blue)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(speech.isListening ? Text("받아쓰기 멈추기") : Text("받아쓰기"))
                        .disabled(!speech.permissionGranted && permissionAsked)
                    }
                    if speech.isListening {
                        Text("듣는 중… 말이 끝나면 자동 종료")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(AppLanguage.learning.localizedName)
                } footer: {
                    Text("🎤 버튼으로 직접 받아쓰기 가능")
                        .font(.caption2)
                }

                Section("뜻") {
                    TextField("예: 잘 지내?", text: $korean, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    TextField("예: 카페에서 점원이 한 말", text: $context, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Text("맥락 (선택)")
                } footer: {
                    Text("누가 어떤 상황에서 한 말이었는지 한 줄로 적어두면 나중에 떠올리기 쉬워요.")
                        .font(.caption2)
                }

                Section {
                    Picker("긍·부정", selection: $polarity) {
                        Text("긍정 +").tag(Polarity.positive)
                        Text("중립").tag(Polarity.neutral)
                        Text("부정 −").tag(Polarity.negative)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("뉘앙스")
                } footer: {
                    Text("긍정/부정 표현은 연습 시 점수와 코칭에 반영돼요.")
                        .font(.caption2)
                }

                Section {
                    Toggle(isOn: $inKeyboard) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard").foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("키보드에 표시").scaledFont(size: 14, weight: .medium)
                                Text("말문 표현 키보드에서 한 번 탭으로 입력 가능")
                                    .scaledFont(size: 11).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? Text("표현 추가") : Text("표현 수정"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", systemImage: "checkmark") {
                        save()
                    }
                    .disabled(trimmed(indonesian).isEmpty || trimmed(korean).isEmpty)
                }
            }
            .task {
                if !permissionAsked {
                    permissionAsked = true
                    await speech.requestPermissions()
                }
            }
            .onChange(of: speech.recognizedText) { _, newValue in
                if speech.isListening, !newValue.isEmpty {
                    indonesian = newValue
                }
            }
        }
    }

    private func toggleDictation() {
        if speech.isListening {
            speech.stopListening()
            return
        }
        do {
            try speech.startListening(onSilence: nil)
        } catch {
            print("Dictation start failed: \(error)")
        }
    }

    private func save() {
        if var existing = editing {
            existing.indonesian = trimmed(indonesian)
            existing.korean = trimmed(korean)
            existing.context = trimmed(context)
            existing.polarity = polarity
            existing.inKeyboard = inKeyboard
            store.update(existing)
        } else {
            let phrase = MyPhrase(
                indonesian: trimmed(indonesian),
                korean: trimmed(korean),
                context: trimmed(context),
                polarity: polarity,
                inKeyboard: inKeyboard
            )
            store.add(phrase)
        }
        dismiss()
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 입력칸 예시

/// 표현·응답·시나리오 입력칸에 보여 줄 예시 문장 (배우는 언어로 쓴 것)
extension AppLanguage {
    /// 안부 인사 — "잘 지내?"
    var sampleGreeting: String {
        switch self {
        case .indonesian: return "Apa kabar?"
        case .english: return "How are you?"
        case .japanese: return "お元気ですか？"
        case .chinese: return "你好吗？"
        case .spanish: return "¿Cómo estás?"
        case .korean: return "잘 지내?"
        }
    }

    /// 짧은 대답 — "응, 좋아!"
    var sampleReply: String {
        switch self {
        case .indonesian: return "Iya, boleh!"
        case .english: return "Yes, sure!"
        case .japanese: return "はい、いいですよ！"
        case .chinese: return "好的，可以！"
        case .spanish: return "¡Sí, claro!"
        case .korean: return "응, 좋아!"
        }
    }

    /// sampleReply 의 한글 발음 (한국어 화면에서만 쓴다)
    var sampleReplyHangul: String {
        switch self {
        case .indonesian: return "이야, 볼레!"
        case .english: return "예스, 슈어!"
        case .japanese: return "하이, 이이데스요!"
        case .chinese: return "하오더, 커이!"
        case .spanish: return "시, 끌라로!"
        case .korean: return "응, 좋아!"
        }
    }

    /// 시나리오 제목 — "시장에서"
    var sampleTitle: String {
        switch self {
        case .indonesian: return "Di Pasar"
        case .english: return "At the Market"
        case .japanese: return "市場で"
        case .chinese: return "在市场"
        case .spanish: return "En el mercado"
        case .korean: return "시장에서"
        }
    }

    /// 첫 마디 — "안녕하세요!" (낮 인사)
    var sampleOpener: String {
        switch self {
        case .indonesian: return "Selamat siang!"
        case .english: return "Good afternoon!"
        case .japanese: return "こんにちは！"
        case .chinese: return "下午好！"
        case .spanish: return "¡Buenas tardes!"
        case .korean: return "안녕하세요!"
        }
    }

    /// sampleOpener 의 한글 발음 (한국어 화면에서만 쓴다)
    var sampleOpenerHangul: String {
        switch self {
        case .indonesian: return "슬라맛 시앙"
        case .english: return "굿 애프터눈"
        case .japanese: return "곤니치와"
        case .chinese: return "시아우 하오"
        case .spanish: return "부에나스 따르데스"
        case .korean: return "안녕하세요"
        }
    }
}
