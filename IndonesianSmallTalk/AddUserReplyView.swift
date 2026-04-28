import SwiftUI

struct AddUserReplyView: View {
    let parentNodeId: String
    @EnvironmentObject var store: UserReplyStore
    @EnvironmentObject var phraseStore: PhraseStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechManager()

    @State private var indonesian = ""
    @State private var korean = ""
    @State private var romanization = ""
    @State private var polarity: Polarity = .neutral
    @State private var permissionAsked = false
    @State private var showPhrasePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: { showPhrasePicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "books.vertical.fill")
                            Text("내 표현에서 고르기")
                            if !phraseStore.phrases.isEmpty {
                                Text("(\(phraseStore.phrases.count))")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }

                Section {
                    HStack(alignment: .top, spacing: 8) {
                        TextField("예: Iya, boleh!", text: $indonesian, axis: .vertical)
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
                }

                Section("한국어 뜻") {
                    TextField("예: 응, 좋아!", text: $korean, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    TextField("예: 이야 볼레", text: $romanization)
                } header: {
                    Text("발음 (선택)")
                } footer: {
                    Text("선택 사항이지만 적어두면 학습에 도움이 돼요.")
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
                    Text("긍정/부정 응답은 연습 점수와 코칭에 반영돼요.")
                        .font(.caption2)
                }
            }
            .navigationTitle("내 대답 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
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
            .sheet(isPresented: $showPhrasePicker) {
                PhrasePickerView { phrase in
                    indonesian = phrase.indonesian
                    korean = phrase.korean
                    polarity = phrase.polarity
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
        let reply = UserReply(
            parentNodeId: parentNodeId,
            indonesian: trimmed(indonesian),
            korean: trimmed(korean),
            romanization: trimmed(romanization),
            polarity: polarity
        )
        store.add(reply)
        dismiss()
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
