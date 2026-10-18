import SwiftUI

// MARK: - Brand

/// 말문 브랜드 색. 아이콘(scripts/make_app_icon.py)과 같은 남색 → 파랑, 문틈 빛은 주황.
enum Brand {
    static let deep = Color(red: 0.12, green: 0.16, blue: 0.47)
    static let blue = Color(red: 0.23, green: 0.30, blue: 0.79)
    static let glow = Color(red: 1.00, green: 0.71, blue: 0.28)

    static var gradient: LinearGradient {
        LinearGradient(colors: [blue, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Language Picker

/// 배울 언어 고르기. 화면 언어는 목록에서 빠진다.
struct LanguageGrid: View {
    @Binding var selection: AppLanguage

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AppLanguage.learnable) { lang in
                Button { selection = lang } label: {
                    VStack(spacing: 6) {
                        Text(lang.flag).font(.system(size: 34))
                        Text(lang.localizedName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        if lang.localizedName != lang.endonym {
                            Text(lang.endonym)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selection == lang ? Brand.blue : Color.clear, lineWidth: 2.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == lang ? .isSelected : [])
            }
        }
    }
}

/// 홈 머리말의 국기를 누르면 뜨는 언어 바꾸기 시트
struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LanguagePrefs.learningKey, store: LanguagePrefs.defaults) private var learningRaw = ""
    @State private var selection = AppLanguage.learning

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("무슨 언어를 연습할까요?")
                        .font(.system(size: 22, weight: .bold))
                    Text("언어마다 내 표현·내 시나리오·단어장이 따로 저장돼요. 언제든 다시 바꿀 수 있어요.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    LanguageGrid(selection: $selection)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("바꾸기") {
                        learningRaw = selection.rawValue
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selection == AppLanguage.learning && LanguagePrefs.hasChosenLearning)
                }
            }
        }
    }
}
