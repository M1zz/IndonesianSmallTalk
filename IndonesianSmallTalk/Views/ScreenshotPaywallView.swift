#if DEBUG
import SwiftUI
import LeeoKit

/// 인앱 구매 심사용 스크린샷 전용 (Debug 빌드에만 있다).
///
/// 상품이 아직 App Store Connect 에 없으면 시뮬레이터가 가격을 못 불러와 LeeoPaywallView 가 빈 칸으로 뜬다.
/// 그래서 실행 인자로 가격을 받아, LeeoPaywallView 와 같은 배치·같은 문구(LeeoKit 번역)로 그린다.
///   -ScreenshotPaywall "$19.99,$39.99"   (연간, 평생 순서)
///   -ScreenshotSelect lifetime           (선택된 상품, 기본은 yearly)
/// 찍는 스크립트: scripts/capture_paywall_screenshot.sh
struct ScreenshotPaywallView: View {
    let yearlyPrice: String
    let lifetimePrice: String
    let selected: String   // "yearly" | "lifetime"

    private let theme = LeeoStyle(accent: Brand.solidBlue)

    static var launchConfig: (yearly: String, lifetime: String, selected: String)? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ScreenshotPaywall"), i + 1 < args.count else { return nil }
        let prices = args[i + 1].split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard prices.count == 2 else { return nil }
        var selected = "yearly"
        if let j = args.firstIndex(of: "-ScreenshotSelect"), j + 1 < args.count { selected = args[j + 1] }
        return (prices[0], prices[1], selected)
    }

    /// LeeoKit 의 번역을 그대로 쓴다 (실제 페이월과 같은 문구)
    private func L(_ key: String) -> String {
        let bundle = Bundle.main.url(forResource: "LeeoKit_LeeoKit", withExtension: "bundle").flatMap(Bundle.init(url:)) ?? .main
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// App Store Connect 에 넣을 상품 표시 이름·설명 (Products.storekit 과 같은 문구)
    private var names: (yearly: (String, String), lifetime: (String, String)) {
        switch AppLanguage.native {
        case .korean: return (("말문 Pro 연간", "퇴근길 모드 무제한과 상황별 회화 전체."), ("말문 Pro 평생", "퇴근길 모드 무제한과 상황별 회화 전체 — 한 번 결제로 평생."))
        case .japanese: return (("Malmun Pro 年額", "通勤モード無制限とすべてのシーン別会話。"), ("Malmun Pro 買い切り", "通勤モード無制限とすべてのシーン別会話。一度の購入でずっと使えます。"))
        case .chinese: return (("Malmun Pro 年度", "无限通勤模式和全部情景对话。"), ("Malmun Pro 永久版", "无限通勤模式和全部情景对话，一次购买永久使用。"))
        case .spanish: return (("Malmun Pro anual", "Modo trayecto sin límites y todos los diálogos por situación."), ("Malmun Pro de por vida", "Modo trayecto sin límites y todos los diálogos por situación. Pagas una vez y es tuyo."))
        case .indonesian: return (("Malmun Pro Tahunan", "Mode Perjalanan tanpa batas dan semua dialog situasi."), ("Malmun Pro Seumur Hidup", "Mode Perjalanan tanpa batas dan semua dialog situasi. Bayar sekali, milikmu selamanya."))
        case .english: return (("Malmun Pro Yearly", "Unlimited Commute Mode and every situational dialogue."), ("Malmun Pro Lifetime", "Unlimited Commute Mode and every situational dialogue — pay once, yours forever."))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(theme.accent)
                        .padding(.top, 28)
                    Text(String(format: L("%@ 프리미엄"), MalmunSpec.displayName))
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(L("모든 기능을 잠금 해제하세요."))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textMuted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(MalmunPro.paywallFeatures, id: \.self) { feature in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.accent)
                            Text(feature)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.radiusLg))

                VStack(spacing: 12) {
                    row(names.yearly, price: "\(yearlyPrice) / \(L("년"))", isSelected: selected != "lifetime")
                    row(names.lifetime, price: lifetimePrice, isSelected: selected == "lifetime")
                }
                Text(selected == "lifetime" ? L("구매하기") : L("구독 시작하기"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.accent, in: RoundedRectangle(cornerRadius: theme.radiusLg))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    Text(L("구매 복원")).font(.footnote).foregroundStyle(theme.accent)
                    Text(L("결제는 App Store 계정으로 청구됩니다. 구독은 언제든지 App Store 설정에서 관리·해지할 수 있어요."))
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textFaint)
                    HStack(spacing: 16) {
                        Text(L("이용약관"))
                        Text(L("개인정보처리방침"))
                    }
                    .font(.caption2)
                    .foregroundStyle(theme.textMuted)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(theme.bg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(theme.textFaint)
                .padding(16)
        }
    }

    private func row(_ name: (String, String), price: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? theme.accent : theme.textFaint)
            VStack(alignment: .leading, spacing: 2) {
                Text(name.0).font(.headline)
                Text(name.1).font(.caption).foregroundStyle(theme.textMuted)
            }
            Spacer(minLength: 8)
            Text(price).font(.headline)
        }
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.radiusLg))
        .overlay(RoundedRectangle(cornerRadius: theme.radiusLg).stroke(isSelected ? theme.accent : .clear, lineWidth: 2))
    }
}
#endif
