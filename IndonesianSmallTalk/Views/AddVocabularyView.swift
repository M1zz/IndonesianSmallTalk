import SwiftUI

struct AddVocabularyView: View {
    var editing: VocabWord? = nil
    @EnvironmentObject var store: VocabularyStore
    @Environment(\.dismiss) private var dismiss

    @State private var indonesian: String
    @State private var korean: String
    @State private var romanization: String
    @State private var category: String
    @State private var notes: String

    init(editing: VocabWord? = nil) {
        self.editing = editing
        _indonesian   = State(initialValue: editing?.indonesian ?? "")
        _korean       = State(initialValue: editing?.korean ?? "")
        _romanization = State(initialValue: editing?.romanization ?? "")
        _category     = State(initialValue: editing?.category ?? "기타")
        _notes        = State(initialValue: editing?.notes ?? "")
    }

    private var canSave: Bool {
        !indonesian.trimmingCharacters(in: .whitespaces).isEmpty &&
        !korean.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("인도네시아어 *") {
                    TextField("예: sibuk", text: $indonesian)
                        .autocorrectionDisabled()
                }

                Section("한국어 뜻 *") {
                    TextField("예: 바쁜", text: $korean)
                }

                Section {
                    TextField("예: 시북", text: $romanization)
                } header: {
                    Text("발음 (선택)")
                } footer: {
                    Text("한글로 발음을 적어두면 학습에 도움이 돼요.")
                        .font(.caption2)
                }

                Section("품사") {
                    Picker("품사", selection: $category) {
                        ForEach(VocabWord.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("예: 주로 'lagi sibuk'으로 사용해요", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Text("메모 (선택)")
                }
            }
            .navigationTitle(editing != nil ? "단어 수정" : "단어 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trim = { (s: String) in s.trimmingCharacters(in: .whitespacesAndNewlines) }
        if var existing = editing {
            existing.indonesian   = trim(indonesian)
            existing.korean       = trim(korean)
            existing.romanization = trim(romanization)
            existing.category     = category
            existing.notes        = trim(notes)
            store.update(existing)
        } else {
            store.add(VocabWord(
                indonesian:   trim(indonesian),
                korean:       trim(korean),
                romanization: trim(romanization),
                category:     category,
                notes:        trim(notes)
            ))
        }
        dismiss()
    }
}
