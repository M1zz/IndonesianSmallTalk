import SwiftUI

struct KeyboardManageView: View {
    @EnvironmentObject var store: PhraseStore
    @EnvironmentObject var slangStore: SlangStore
    @State private var search = ""
    @State private var slangEnabled: Bool = KeyboardSettings.slangEnabled
    @State private var direction: InputDirection = KeyboardSettings.inputDirection
    @State private var showSlangManage = false

    private var visibleCount: Int { store.phrases.filter { $0.inKeyboard }.count }
    private var hiddenCount: Int { store.phrases.count - visibleCount }

    private var filtered: [MyPhrase] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else {
            return store.phrases
        }
        let q = search.lowercased()
        return store.phrases.filter {
            $0.indonesian.lowercased().contains(q)
                || $0.korean.lowercased().contains(q)
                || $0.context.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            Section {
                directionPicker
            } header: {
                Text("입력 방향")
            } footer: {
                Text("키보드에서 어느 언어를 보고 어느 언어를 입력할지. 키보드 우상단 칩으로도 즉시 전환할 수 있어요.")
                    .font(.caption2)
            }

            Section {
                slangToggleRow
                if slangEnabled {
                    Button(action: { showSlangManage = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.pink)
                            Text("슬랭 관리 (\(slangStore.pairs.count))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("슬랭")
            } footer: {
                Text("한국어 젠지어와 비슷한 의미·톤의 인도네시아어 슬랭. 추가/수정/삭제하면 키보드에 즉시 반영돼요.")
                    .font(.caption2)
            }

            if store.phrases.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        Text("아직 표현이 없어요")
                            .font(.system(size: 14, weight: .semibold))
                        Text("+ 새 표현 으로 추가하면 여기서 키보드 노출 여부를 관리할 수 있어요")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                Section {
                    summaryRow
                    bulkButtons
                    sortButtons
                }

                Section(header: phraseSectionHeader) {
                    ForEach(filtered) { phrase in
                        row(for: phrase)
                    }
                    .onMove(perform: handleMove)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $search, prompt: "한국어 / 인도네시아어 검색")
        .navigationTitle("키보드 관리")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSlangManage) {
            SlangManageView()
        }
    }

    private var directionPicker: some View {
        Picker("입력 방향", selection: $direction) {
            Text("한 → 인 (한국어 보고 인도네시아어 입력)").tag(InputDirection.kor2ind)
            Text("인 → 한 (인도네시아어 보고 한국어 입력)").tag(InputDirection.ind2kor)
        }
        .pickerStyle(.inline)
        .labelsHidden()
        .onChange(of: direction) { _, newValue in
            KeyboardSettings.inputDirection = newValue
        }
    }

    private var slangToggleRow: some View {
        Toggle(isOn: $slangEnabled) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("한국어 ↔ 인도네시아어 슬랭")
                        .font(.system(size: 14, weight: .medium))
                    Text("ㅋㅋㅋ → wkwkwk / 헐 → Anjir 같은 매핑")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: slangEnabled) { _, newValue in
            KeyboardSettings.slangEnabled = newValue
        }
    }

    private var phraseSectionHeader: some View {
        HStack {
            Text("표현 (\(filtered.count))")
            Spacer()
            EditButton().font(.caption.bold())
        }
    }

    private func handleMove(from source: IndexSet, to destination: Int) {
        guard search.isEmpty else { return }
        store.move(from: source, to: destination)
    }

    private var sortButtons: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation { store.sortByStudyCount() }
            } label: {
                Label("연습 많이순", systemImage: "flame.fill")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            Button {
                withAnimation { store.sortByRecent() }
            } label: {
                Label("최신순", systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.pink)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("키보드에 표시 중")
                    .font(.caption).foregroundColor(.secondary)
                Text("\(visibleCount)").font(.system(size: 26, weight: .bold))
                    .foregroundColor(.blue)
            }
            Divider().frame(height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text("숨김").font(.caption).foregroundColor(.secondary)
                Text("\(hiddenCount)").font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            Spacer()
            Image(systemName: "keyboard")
                .font(.system(size: 28))
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }

    private var bulkButtons: some View {
        HStack(spacing: 10) {
            Button {
                store.setAllInKeyboard(true)
            } label: {
                Label("전체 켜기", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            Button {
                store.setAllInKeyboard(false)
            } label: {
                Label("전체 끄기", systemImage: "minus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.gray.opacity(0.12))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    private func row(for phrase: MyPhrase) -> some View {
        let binding = Binding<Bool>(
            get: { phrase.inKeyboard },
            set: { _ in store.toggleInKeyboard(id: phrase.id) }
        )
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(phrase.indonesian)
                        .font(.system(size: 15, weight: .semibold))
                    PolarityChip(polarity: phrase.polarity)
                    if phrase.studyCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("\(phrase.studyCount)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(4)
                    }
                }
                Text(phrase.korean)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                if !phrase.context.isEmpty {
                    Text(phrase.context)
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("관리할 표현이 없어요").font(.headline)
            Text("먼저 + 버튼으로 표현을 추가해주세요")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

