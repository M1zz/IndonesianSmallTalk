import SwiftUI

struct SlangManageView: View {
    @EnvironmentObject var store: SlangStore
    @State private var editing: SlangPair?
    @State private var showAdd = false
    @State private var confirmReset = false

    var body: some View {
        List {
            Section {
                ForEach(store.pairs) { pair in
                    Button {
                        editing = pair
                    } label: {
                        slangRow(pair)
                    }
                    .buttonStyle(.plain)
                }
                .onMove { src, dst in store.move(from: src, to: dst) }
                .onDelete { idx in
                    for i in idx { store.delete(id: store.pairs[i].id) }
                }
            } header: {
                HStack {
                    Text("슬랭 (\(store.pairs.count))")
                    Spacer()
                    EditButton().font(.caption.bold())
                }
            } footer: {
                Text("이 매핑은 1:1 정확한 번역이 아닌 비슷한 톤·뉘앙스 매칭이에요. 격식 자리에선 인도네시아어 슬랭 사용에 주의하세요.")
                    .font(.caption2)
            }

            Section {
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("기본값으로 복원", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text("내가 추가/수정/삭제한 슬랭이 모두 사라지고 내장 \(BuiltInSlang.seedItems.count)개로 다시 채워집니다.")
                    .font(.caption2)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("슬랭 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            EditSlangView(editing: nil)
        }
        .sheet(item: $editing) { pair in
            EditSlangView(editing: pair)
        }
        .alert("기본값으로 복원", isPresented: $confirmReset) {
            Button("취소", role: .cancel) {}
            Button("복원", role: .destructive) { store.resetToDefaults() }
        } message: {
            Text("내가 추가/수정/삭제한 슬랭이 모두 사라집니다.")
        }
    }

    private func slangRow(_ pair: SlangPair) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(pair.korean)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(pair.indonesian)
                    .font(.system(size: 14))
                    .foregroundColor(.pink)
            }
            if !pair.note.isEmpty {
                Text(pair.note)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct EditSlangView: View {
    var editing: SlangPair?

    @EnvironmentObject var store: SlangStore
    @Environment(\.dismiss) private var dismiss

    @State private var korean: String
    @State private var indonesian: String
    @State private var note: String

    init(editing: SlangPair?) {
        self.editing = editing
        _korean = State(initialValue: editing?.korean ?? "")
        _indonesian = State(initialValue: editing?.indonesian ?? "")
        _note = State(initialValue: editing?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("한국어") {
                    TextField("예: 헐", text: $korean)
                }
                Section("인도네시아어") {
                    TextField("예: Anjir!", text: $indonesian)
                        .autocorrectionDisabled()
                }
                Section {
                    TextField("예: 놀람", text: $note)
                } header: {
                    Text("뉘앙스 (선택)")
                } footer: {
                    Text("키보드 행에 작은 글씨로 같이 표시됩니다.")
                        .font(.caption2)
                }
            }
            .navigationTitle(editing == nil ? "슬랭 추가" : "슬랭 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(trimmed(korean).isEmpty || trimmed(indonesian).isEmpty)
                }
            }
        }
    }

    private func save() {
        if var existing = editing {
            existing.korean = trimmed(korean)
            existing.indonesian = trimmed(indonesian)
            existing.note = trimmed(note)
            store.update(existing)
        } else {
            store.add(SlangPair(
                korean: trimmed(korean),
                indonesian: trimmed(indonesian),
                note: trimmed(note)
            ))
        }
        dismiss()
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
