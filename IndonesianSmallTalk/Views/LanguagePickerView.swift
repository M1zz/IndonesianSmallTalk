import SwiftUI

// MARK: - Brand

/// 말문 브랜드 색. 아이콘(scripts/make_app_icon.py)과 같은 남색 → 파랑, 문틈 빛은 주황.
enum Brand {
    static let deep = Color(red: 0.12, green: 0.16, blue: 0.47)
    /// 글자·아이콘에 쓰는 파랑. 어두운 화면에서는 밝게 바꿔 잘 보이게 한다.
    static let blue = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.49, green: 0.58, blue: 1.00, alpha: 1)
            : UIColor(red: 0.23, green: 0.30, blue: 0.79, alpha: 1)
    })
    /// 바탕용 파랑 (화면 모드와 상관없이 같음)
    static let solidBlue = Color(red: 0.23, green: 0.30, blue: 0.79)
    static let glow = Color(red: 1.00, green: 0.71, blue: 0.28)

    static var gradient: LinearGradient {
        LinearGradient(colors: [solidBlue, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Dynamic Type

extension View {
    /// 디자인에서 정한 글자 크기를 '더 큰 텍스트' 설정만큼 키운다.
    /// 기본 크기에서는 그대로이고, 크기가 가까운 글꼴 스타일과 같은 비율로 커진다.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

private struct ScaledFont: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size, compatibleWith: traits)
        content.font(.system(size: scaled, weight: weight, design: design))
    }

    /// 기본 크기가 가장 가까운 글꼴 스타일
    private var textStyle: UIFont.TextStyle {
        switch size {
        case ..<11.5: .caption2
        case ..<12.5: .caption1
        case ..<14: .footnote
        case ..<15.5: .subheadline
        case ..<16.5: .callout
        case ..<19: .body
        case ..<21: .title3
        case ..<25: .title2
        case ..<31: .title1
        default: .largeTitle
        }
    }
}

extension View {
    /// 한 줄로 두되, 손쉬운 사용 큰 글자에서는 잘리지 않게 줄을 바꾼다.
    func singleLine() -> some View { modifier(SingleLine()) }
}

private struct SingleLine: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    func body(content: Content) -> some View {
        content.lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
    }
}

extension View {
    /// 탭 제스처로만 되던 동작을 VoiceOver·음성 명령에서도 누를 수 있는 버튼으로 알린다.
    func accessibleTap(hint: LocalizedStringKey, _ action: @escaping () -> Void) -> some View {
        accessibilityAddTraits(.isButton)
            .accessibilityHint(Text(hint))
            .accessibilityAction(.default, action)
    }
}

extension AnyTransition {
    /// '동작 줄이기'를 켜 두면 미끄러지지 않고 흐려지기만 한다.
    static func motion(_ transition: AnyTransition) -> AnyTransition {
        UIAccessibility.isReduceMotionEnabled ? .opacity : transition
    }
}

extension Color {
    /// 밝은 화면과 어두운 화면에서 다른 색
    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
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
                            .scaledFont(size: 15, weight: .semibold)
                            .foregroundColor(.primary)
                        if lang.localizedName != lang.endonym {
                            Text(lang.endonym)
                                .scaledFont(size: 11)
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
                        .scaledFont(size: 22, weight: .bold)
                    Text("언어마다 내 표현·내 시나리오·단어장이 따로 저장돼요. 언제든 다시 바꿀 수 있어요.")
                        .scaledFont(size: 13)
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
