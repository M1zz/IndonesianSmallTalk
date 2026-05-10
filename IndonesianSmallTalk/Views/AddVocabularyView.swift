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
    @State private var tier: Int
    @State private var examples: [VocabExample]

    init(editing: VocabWord? = nil) {
        self.editing = editing
        _indonesian   = State(initialValue: editing?.indonesian ?? "")
        _korean       = State(initialValue: editing?.korean ?? "")
        _romanization = State(initialValue: editing?.romanization ?? "")
        _category     = State(initialValue: editing?.category ?? "기타")
        _notes        = State(initialValue: editing?.notes ?? "")
        _tier         = State(initialValue: editing?.tier ?? 2)
        _examples     = State(initialValue: editing?.examples ?? [])
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
                    TextField("예: 바쁘다", text: $korean)
                }

                Section {
                    TextField("예: 시북", text: $romanization)
                } header: {
                    Text("발음 (선택)")
                } footer: {
                    Text("한글로 발음을 적어두면 학습에 도움이 돼요.")
                        .font(.caption2)
                }

                Section("카테고리") {
                    Picker("카테고리", selection: $category) {
                        ForEach(VocabWord.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Picker("우선순위", selection: $tier) {
                        Text("필수").tag(1)
                        Text("편의").tag(2)
                        Text("심화").tag(3)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("우선순위")
                } footer: {
                    Text("필수: 무조건 외워야 함 / 편의: 알면 좋음 / 심화: 자연스러움 추가")
                        .font(.caption2)
                }

                Section {
                    ForEach(examples.indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("인도네시아어 예문",
                                      text: Binding(
                                        get: { examples[idx].indonesian },
                                        set: { examples[idx].indonesian = $0 }
                                      ))
                                .autocorrectionDisabled()
                                .font(.system(size: 14, weight: .medium))
                            TextField("한국어 뜻",
                                      text: Binding(
                                        get: { examples[idx].korean },
                                        set: { examples[idx].korean = $0 }
                                      ))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        examples.remove(atOffsets: offsets)
                    }
                    Button {
                        examples.append(VocabExample("", ""))
                    } label: {
                        Label("예문 추가", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                    }
                } header: {
                    Text("예문 (선택, 여러 개 가능)")
                } footer: {
                    Text("같은 단어를 여러 상황에서 본 예문일수록 외우기 쉬워요.")
                        .font(.caption2)
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
        let cleanedExamples = examples.compactMap { ex -> VocabExample? in
            let i = trim(ex.indonesian)
            let k = trim(ex.korean)
            return (i.isEmpty && k.isEmpty) ? nil : VocabExample(i, k)
        }
        if var existing = editing {
            existing.indonesian   = trim(indonesian)
            existing.korean       = trim(korean)
            existing.romanization = trim(romanization)
            existing.category     = category
            existing.notes        = trim(notes)
            existing.tier         = tier
            existing.examples     = cleanedExamples
            store.update(existing)
        } else {
            store.add(VocabWord(
                indonesian:   trim(indonesian),
                korean:       trim(korean),
                romanization: trim(romanization),
                category:     category,
                notes:        trim(notes),
                examples:     cleanedExamples,
                tier:         tier
            ))
        }
        dismiss()
    }
}
