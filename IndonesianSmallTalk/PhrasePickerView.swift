import SwiftUI

struct PhrasePickerView: View {
    @EnvironmentObject var store: PhraseStore
    @Environment(\.dismiss) private var dismiss
    let onPick: (MyPhrase) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.phrases.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("저장된 표현이 없어요")
                            .font(.headline)
                        Text("홈 화면의 + 버튼으로 표현을 먼저 저장해보세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(store.phrases) { phrase in
                            Button(action: {
                                onPick(phrase)
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(phrase.indonesian)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        PolarityChip(polarity: phrase.polarity)
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
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("내 표현에서 고르기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}
