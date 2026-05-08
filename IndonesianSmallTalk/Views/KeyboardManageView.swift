import SwiftUI

struct KeyboardManageView: View {
    @EnvironmentObject var store: PhraseStore
    @State private var search = ""

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
        Group {
            if store.phrases.isEmpty {
                emptyState
            } else {
                List {
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
                .listStyle(.insetGrouped)
                .searchable(text: $search, prompt: "한국어 / 인도네시아어 검색")
            }
        }
        .navigationTitle("키보드 관리")
        .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundColor(.purple)
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
