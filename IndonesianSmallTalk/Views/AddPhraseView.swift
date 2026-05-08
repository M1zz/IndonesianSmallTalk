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
                    HStack(alignment: .top, spacing: 8) {
                        TextField("예: Apa kabar?", text: $indonesian, axis: .vertical)
                            .lineLimit(1...3)
                            .autocorrectionDisabled()
                        Button(action: toggleDictation) {
                            Image(systemName: speech.isListening ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(speech.isListening ? .red : .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(!speech.permissionGranted && permissionAsked)
                    }
                    if speech.isListening {
                        Text("듣는 중… 말이 끝나면 자동 종료")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("인도네시아어")
                } footer: {
                    Text("🎤 버튼으로 직접 받아쓰기 가능")
                        .font(.caption2)
                }

                Section("한국어 뜻") {
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
                                Text("키보드에 표시").font(.system(size: 14, weight: .medium))
                                Text("사노라면 표현 키보드에서 한 번 탭으로 입력 가능")
                                    .font(.system(size: 11)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "표현 추가" : "표현 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
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
