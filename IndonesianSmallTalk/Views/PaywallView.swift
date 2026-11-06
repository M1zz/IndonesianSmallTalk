import SwiftUI
import StoreKit
import LeeoKit

/// 말문 Plus · Pro 를 파는 한 장. 머리말 → 비교표 → 칸 카드(연 구독 · 평생, 주 · 월은 펼쳐서) → 약관.
///
/// **무료로 되는 것을 비교표에 먼저 보인다.** 이 화면을 닫고 나서도 앱은 그대로 쓴다.
/// 첫 해 할인(App Store 첫 구독 할인)과 "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 알아서 보인다.
/// 스토어에 아직 없는 상품은 불러오지 못하므로 그 단추가 서지 않는다(빈 단추를 누르게 두지 않는다).
struct PaywallView: View {
    /// 어디서 들어왔는가. 그 칸을 위에 세우고 비교표의 그 줄을 짚는다.
    var feature: ProFeature?

    @ObservedObject private var pro = MalmunPro.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 **이 페이월이 떠 있는 창**에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    /// 칸마다 고른 길. 처음엔 연 구독.
    @State private var terms: [ProTier: LeeoPlanTerm] = [:]
    /// 칸마다 고른 주 · 월 구독. 있으면 `terms` 보다 앞선다.
    @State private var shortPlans: [ProTier: String] = [:]
    @State private var loadingProducts = true
    @State private var redeemingCode = false

    private var highlight: ProTier? { feature?.tier }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    comparison
                    plansStatus
                    ForEach(cardOrder) { tierCard($0) }
                    if let message = pro.failureMessage, !pro.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(.orange)
                    }
                    legal
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("요금제", comment: "Paywall: navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "나중에", comment: "Paywall: close button")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "구매 복원")) {
                        Task {
                            await pro.restore()
                            if pro.tier > .free { dismiss() }
                        }
                    }
                    .disabled(pro.isWorking)
                }
            }
            // 코드를 넣고 돌아오면 영수증을 다시 읽는다.
            .offerCodeRedemption(isPresented: $redeemingCode) { _ in
                Task {
                    await pro.refresh()
                    if pro.tier > .free { dismiss() }
                }
            }
            .task {
                LeeoAnalyticsCenter.track(.paywallShown(reason: feature?.rawValue ?? "general"))
                await loadPlans()
            }
        }
        .tint(Brand.blue)
        .leeoStyle(LeeoStyle(accent: Brand.solidBlue))
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("말문 Plus · Pro", comment: "Paywall title. Malmun is the app name")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("여행지의 모든 상황, 그리고 출퇴근길마다 귀로 연습하기. 연 구독이나 평생 중에 고르세요.", comment: "Paywall: subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let feature {
                Label {
                    Text(feature.reason)
                } icon: {
                    Image(systemName: "lock.fill")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Brand.blue)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            }
        }
    }

    // MARK: 비교표

    private var comparison: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(ProTier.allCases) { tier in
                    Text(verbatim: tier.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tier == highlight ? Brand.blue : .primary)
                        .gridColumnAlignment(.center)
                }
            }
            .accessibilityHidden(true)
            Divider()
            ForEach(PlanComparisonRow.all) { row in
                GridRow {
                    Text(row.title)
                        .font(row.feature != nil && row.feature == feature ? .body.weight(.semibold) : .body)
                        .fixedSize(horizontal: false, vertical: true)
                    cell(row.free)
                    cell(row.plus)
                    cell(row.pro)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.title)
                .accessibilityValue(accessibilityValue(row))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    @ViewBuilder
    private func cell(_ cell: PlanComparisonRow.Cell) -> some View {
        switch cell {
        case .yes:
            Image(systemName: "checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(Brand.blue)
        case .no:
            Text(verbatim: "–")
                .font(.body)
                .foregroundStyle(.tertiary)
        case .text(let text):
            Text(text)
                .font(.body)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func accessibilityValue(_ row: PlanComparisonRow) -> String {
        zip(ProTier.allCases, [row.free, row.plus, row.pro]).map { tier, cell in
            let value: String
            switch cell {
            case .yes: value = String(localized: "포함", comment: "Paywall comparison (VoiceOver): the plan includes this")
            case .no: value = String(localized: "없음", comment: "Paywall comparison (VoiceOver): the plan does not include this")
            case .text(let text): value = text
            }
            return "\(tier.title) \(value)"
        }.joined(separator: ", ")
    }

    // MARK: 유료 칸

    /// 누른 자리의 칸을 위에. 그 밖에는 Plus → Pro.
    private var cardOrder: [ProTier] {
        highlight == .pro ? [.pro, .plus] : ProTier.paid
    }

    private func tierCard(_ tier: ProTier) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(verbatim: tier.title)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                if pro.tier == tier {
                    Text("지금 쓰는 칸", comment: "Paywall: badge on the plan the person already has")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Brand.blue.opacity(0.12), in: Capsule())
                }
                Spacer(minLength: 0)
            }
            Text(tier.tagline)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            // 이미 이 칸 이상이면 살 것이 없다. 구독을 평생으로 바꾸는 길은 설정에 있다.
            if pro.tier < tier {
                LeeoTermPicker(term: termBinding(tier), yearly: pro.product(ProEntitlement.yearlyID(tier)),
                               lifetime: lifetimeProduct(tier))
                shortPlanOptions(tier)
                buyButton(tier)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape.fill(Color(.secondarySystemGroupedBackground))
            shape.strokeBorder(highlight == tier && pro.tier < tier ? Brand.blue : .clear, lineWidth: 1.5)
        }
    }

    /// 고른 길. 처음엔 연 구독 — 스토어에 연 구독이 아직 없고 평생만 있으면 평생.
    private func term(_ tier: ProTier) -> LeeoPlanTerm {
        if let chosen = terms[tier] { return chosen }
        let hasYearly = pro.product(ProEntitlement.yearlyID(tier)) != nil
        return !hasYearly && lifetimeProduct(tier) != nil ? .lifetime : .yearly
    }

    private func termBinding(_ tier: ProTier) -> Binding<LeeoPlanTerm> {
        Binding(get: { term(tier) },
                set: { terms[tier] = $0; shortPlans[tier] = nil })
    }

    /// 칸의 평생. **Plus 평생을 이미 산 사람에게는 Pro 평생 자리에 올리기 상품을 세운다.**
    private func lifetimeProduct(_ tier: ProTier) -> Product? {
        if tier == .plus { return pro.product(ProEntitlement.plusLifetimeID) }
        return pro.product(upgradesToPro ? ProEntitlement.upgradeID : ProEntitlement.proLifetimeID)
    }

    private var upgradesToPro: Bool { pro.ownsLifetime(.plus) }

    /// 주 · 월 구독. 접어 두고, 펼치면 고른다.
    @ViewBuilder
    private func shortPlanOptions(_ tier: ProTier) -> some View {
        let weekly = pro.product(ProEntitlement.weeklyID(tier))
        let monthly = pro.product(ProEntitlement.monthlyID(tier))
        if weekly != nil || monthly != nil {
            DisclosureGroup {
                VStack(spacing: 8) {
                    if let monthly {
                        shortPlanRow(tier, monthly, title: String(localized: "월 구독 · \(monthly.displayPrice)",
                                                                  comment: "Paywall: monthly plan option. Argument is the price"))
                    }
                    if let weekly {
                        shortPlanRow(tier, weekly, title: String(localized: "주 구독 · \(weekly.displayPrice)",
                                                                 comment: "Paywall: weekly plan option. Argument is the price"))
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("주 · 월 구독으로 보기", comment: "Paywall: expand weekly and monthly plans")
                    .font(.body)
            }
            .tint(.secondary)
        }
    }

    private func shortPlanRow(_ tier: ProTier, _ product: Product, title: String) -> some View {
        let selected = shortPlans[tier] == product.id
        return Button {
            shortPlans[tier] = selected ? nil : product.id
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .monospacedDigit()
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Brand.blue : .secondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 지금 고른 상품과 단추 글.
    private func choice(_ tier: ProTier) -> (Product?, String) {
        if let id = shortPlans[tier], let product = pro.product(id) {
            let title = id == ProEntitlement.weeklyID(tier)
                ? String(localized: "주 구독 시작", comment: "Paywall: buy weekly subscription button")
                : String(localized: "월 구독 시작", comment: "Paywall: buy monthly subscription button")
            return (product, title)
        }
        switch term(tier) {
        case .yearly:
            return (pro.product(ProEntitlement.yearlyID(tier)),
                    String(localized: "연 구독 시작", comment: "Paywall: buy yearly subscription button"))
        case .lifetime:
            let title = tier == .pro && upgradesToPro
                ? String(localized: "Pro 평생으로 올리기", comment: "Paywall: upgrade Plus Lifetime to Pro Lifetime button")
                : String(localized: "평생으로 사기", comment: "Paywall: buy lifetime button")
            return (lifetimeProduct(tier), title)
        }
    }

    private func buyButton(_ tier: ProTier) -> some View {
        let (product, title) = choice(tier)
        return Button {
            guard let product else { return }
            Task {
                await pro.purchase(product, using: purchaseAction)
                if pro.tier >= tier { dismiss() }
            }
        } label: {
            Group {
                if pro.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.solidBlue)
        .controlSize(.large)
        .disabled(pro.isWorking || product == nil)
    }

    // MARK: 요금제를 못 불러왔을 때

    @ViewBuilder
    private var plansStatus: some View {
        if pro.products.isEmpty && loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("값을 불러오는 중…", comment: "Paywall: loading prices")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        } else if pro.products.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("요금제를 불러오지 못했어요. 인터넷 연결을 확인하고 다시 불러와 주세요.", comment: "Paywall: prices failed to load")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label {
                        Text("다시 불러오기", comment: "Paywall: retry loading prices")
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// 첫 조회가 비어 오면 한 번 더 청한다. 샌드박스(심사 환경)는 첫 조회가 빈손으로 오는 일이 잦다.
    private func loadPlans() async {
        loadingProducts = true
        await pro.loadProducts()
        if pro.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await pro.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 요금으로 자동 갱신되고, Apple 계정으로 결제됩니다. 연 구독을 처음 시작하면 첫 해는 할인된 값으로 결제되고 그 뒤에는 정가로 갱신됩니다. 해지와 관리는 App Store 계정 설정에서 할 수 있어요. 평생은 구독이 아니라 한 번만 결제합니다.",
                 comment: "Paywall: auto-renewal terms")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                if let terms = MalmunSpec.monetization.subscriptionTermsURL {
                    Button { openURL(terms) } label: { Text("이용약관", comment: "Paywall: terms of use link") }
                }
                Button { openURL(MalmunSpec.legal.privacyURL) } label: {
                    Text("개인정보 처리방침", comment: "Paywall: privacy policy link")
                }
            }
            .font(.body)
            Button {
                redeemingCode = true
            } label: {
                Label {
                    Text("코드 사용", comment: "Paywall: redeem an offer code")
                } icon: {
                    Image(systemName: "ticket")
                }
            }
            .font(.body)
            .disabled(pro.isWorking)
        }
    }
}

// MARK: - 시트로 띄우기

extension View {
    /// 페이월을 이 화면에서 띄운다. 이미 다른 시트 안에 있는 화면(내 시나리오 만들기 · 가져오기)은
    /// 앱 맨 아래의 페이월 시트가 그 위로 뜨지 못하므로 이것을 쓴다.
    /// - Parameter onUnlocked: 페이월을 닫았을 때 그 기능이 열려 있으면 부른다(하던 일을 마저 한다).
    func malmunPaywall(_ feature: Binding<ProFeature?>, onUnlocked: @escaping (ProFeature) -> Void = { _ in }) -> some View {
        modifier(MalmunPaywallSheet(feature: feature, onUnlocked: onUnlocked))
    }
}

private struct MalmunPaywallSheet: ViewModifier {
    @Binding var feature: ProFeature?
    let onUnlocked: (ProFeature) -> Void
    /// 닫힌 뒤에도 무엇을 열려고 했는지 기억한다(닫히면 `feature` 는 nil 이 된다).
    @State private var shown: ProFeature?

    func body(content: Content) -> some View {
        content.sheet(item: $feature, onDismiss: {
            if let shown, MalmunPro.shared.allows(shown) { onUnlocked(shown) }
            shown = nil
        }) { feature in
            PaywallView(feature: feature)
                .onAppear { shown = feature }
        }
    }
}
