import Combine
import Foundation
import StoreKit
import SwiftUI
import LeeoKit

// MARK: - 칸

/// 말문의 세 칸 — 무료 · Plus · Pro. 값이 클수록 더 많이 연다. Pro 는 Plus 를 전부 포함한다.
/// **무엇이 어느 칸에서 열리는지는 이 파일 한 곳에만 적는다.** 페이월 · 비교표 · 잠긴 자리가 모두 여기를 읽는다.
///
///  · 무료: 6개 언어, 상황별 회화의 기본 · 일상, 스몰토크 · 하루 코스 · 발음 · 대본 · 기록 · 내 문장 · 단어 · 키보드,
///          퇴근길 모드 하루 3장면, 직접 만들거나 가져온 시나리오 3개
///  · Plus: 상황별 회화 53개 전체, 내 시나리오 · 가져오기 무제한
///  · Pro:  Plus 전부 + 퇴근길 모드 무제한, AI 시나리오 만들기, iCloud 로 친구와 나누기
///
/// ⚠️ 잠그지 않는 것: 이미 만든 시나리오 · 받은 시나리오 보기 · 연습 · 고치기 · 지우기, 공유 해제.
///    한도를 넘겨 가진 시나리오(예전 버전에서 만든 것)도 그대로 쓴다. 막는 것은 **새로 만드는 일** 하나다.
enum ProTier: Int, Comparable, CaseIterable, Identifiable {
    case free = 0
    case plus = 1
    case pro = 2

    static func < (lhs: ProTier, rhs: ProTier) -> Bool { lhs.rawValue < rhs.rawValue }
    var id: Int { rawValue }

    /// 유료 칸.
    static let paid: [ProTier] = [.plus, .pro]

    var title: String {
        switch self {
        case .free: return String(localized: "무료", comment: "Plan name: free tier")
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    /// 칸 한 줄.
    var tagline: String {
        switch self {
        case .free: return String(localized: "여섯 언어 회화 연습과 하루 코스, 퇴근길 모드 하루 3장면까지 무료.", comment: "Paywall: one line about the free plan")
        case .plus: return String(localized: "공항부터 긴급 상황까지 53개 상황 전체, 내 시나리오는 원하는 만큼.", comment: "Paywall: one line about Plus")
        case .pro: return String(localized: "출퇴근 내내 귀로 연습하고, 원하는 상황은 AI로 바로 만드세요.", comment: "Paywall: one line about Pro")
        }
    }
}

// MARK: - 값을 받고 여는 것

/// 무료 사용자가 부딪히는 잠금. 페이월은 "방금 누른 그것"의 칸을 앞세워 보여 준다.
enum ProFeature: String, Identifiable, CaseIterable {
    case situations  // 상황별 회화 — 기본 · 일상 대화 밖의 분류
    case scenarios   // 직접 만든 · 가져온 시나리오 4번째부터
    case commute     // 퇴근길 모드 — 하루 무료 장면 수를 넘었을 때
    case aiScenario  // AI 로 시나리오 만들기
    case share       // iCloud 로 친구와 나누기

    var id: String { rawValue }

    /// 이 기능을 여는 가장 낮은 칸.
    var tier: ProTier {
        switch self {
        case .situations, .scenarios: return .plus
        case .commute, .aiScenario, .share: return .pro
        }
    }

    /// 페이월 머리에 "왜 여기 왔는지" 한 줄.
    var reason: String {
        switch self {
        case .situations: return String(localized: "공항 · 숙소 · 식당 · 긴급 같은 상황별 회화는 Plus에서 열려요.", comment: "Paywall reason: locked situational dialogue")
        case .scenarios: return String(localized: "직접 만든 시나리오는 무료로 \(MalmunPro.freeScenarioLimit)개까지예요. Plus는 원하는 만큼 만들 수 있어요.", comment: "Paywall reason: free limit of own scenarios. Argument is the limit, e.g. 3")
        case .commute: return String(localized: "말문 Pro는 하루 제한 없이 들을 수 있어요")
        case .aiScenario: return String(localized: "AI 시나리오 만들기는 Pro에서 열려요.", comment: "Paywall reason: AI scenario builder")
        case .share: return String(localized: "친구와 나누기는 Pro에서 열려요.", comment: "Paywall reason: sharing scenarios with friends over iCloud")
        }
    }
}

// MARK: - 비교표 (페이월에 그대로)

struct PlanComparisonRow: Identifiable {
    enum Cell { case yes, no, text(String) }

    let title: String
    let free: Cell
    let plus: Cell
    let pro: Cell
    /// 이 줄이 말하는 잠금 (페이월이 들어온 이유와 같으면 강조한다).
    var feature: ProFeature?
    var id: String { title }

    static var all: [PlanComparisonRow] {
        let all53 = String(localized: "53개 전체", comment: "Paywall comparison: all 53 situational dialogues")
        let unlimited = String(localized: "무제한", comment: "Paywall comparison: no limit")
        let threeScenes = String(localized: "하루 \(MalmunPro.freeDriveScenesPerDay)장면", comment: "Paywall comparison: commute mode scenes per day, e.g. 3 a day")
        return [
            .init(title: String(localized: "배울 언어 6개", comment: "Paywall comparison row"), free: .yes, plus: .yes, pro: .yes),
            .init(title: String(localized: "상황별 회화", comment: "Paywall comparison row: situational dialogues"),
                  free: .text(String(localized: "기본 · 일상", comment: "Paywall comparison: free situational categories (basics, everyday chat)")),
                  plus: .text(all53), pro: .text(all53), feature: .situations),
            .init(title: String(localized: "하루 코스 · 주간 시간표", comment: "Paywall comparison row"), free: .yes, plus: .yes, pro: .yes),
            .init(title: String(localized: "발음 연습 · 스크립트 · 연습 기록", comment: "Paywall comparison row"), free: .yes, plus: .yes, pro: .yes),
            .init(title: String(localized: "내 문장 · 단어 카드 · 문장 키보드", comment: "Paywall comparison row"), free: .yes, plus: .yes, pro: .yes),
            .init(title: String(localized: "직접 만든 시나리오 · 가져오기", comment: "Paywall comparison row: own scenarios and imported dialogues"),
                  free: .text(String(localized: "\(MalmunPro.freeScenarioLimit)개", comment: "Paywall comparison: free scenario limit, e.g. 3")),
                  plus: .text(unlimited), pro: .text(unlimited), feature: .scenarios),
            .init(title: String(localized: "퇴근길 모드", comment: "Paywall comparison row: commute mode"),
                  free: .text(threeScenes), plus: .text(threeScenes), pro: .text(unlimited), feature: .commute),
            .init(title: String(localized: "AI 시나리오 만들기", comment: "Paywall comparison row"), free: .no, plus: .no, pro: .yes, feature: .aiScenario),
            .init(title: String(localized: "iCloud로 친구와 나누기", comment: "Paywall comparison row"), free: .no, plus: .no, pro: .yes, feature: .share),
        ]
    }
}

// MARK: - 상품

enum ProEntitlement {

    // ⚠️ App Store Connect 의 상품 · `Products.storekit` 과 **글자 하나까지 같아야 한다.**
    //    주 · 월 · 연 구독 여섯 개는 한 구독 그룹(Malmun Pro, Pro 가 위 단계)에 넣는다.
    private static let prefix = "com.devkoan.IndonesianSmallTalk"

    static let plusWeeklyID = "\(prefix).plus.weekly"
    static let plusMonthlyID = "\(prefix).plus.monthly"
    static let plusYearlyID = "\(prefix).plus.yearly"
    static let plusLifetimeID = "\(prefix).plus.lifetime"
    static let proWeeklyID = "\(prefix).pro.weekly"
    static let proMonthlyID = "\(prefix).pro.monthly"
    /// Pro 연 구독. **1.0.x 에서 팔던 '말문 Pro 연간' 그 상품이다.** 지금 구독자는 그대로 Pro.
    static let proYearlyID = "\(prefix).pro.yearly"
    /// Pro 평생. **1.0.x 에서 팔던 '말문 Pro 평생' 그 상품이다.** 산 사람 · 선물받은 사람은 그대로 Pro.
    static let proLifetimeID = "\(prefix).pro.lifetime"
    /// Plus 평생을 산 사람이 Pro 평생으로 올리는 값.
    static let upgradeID = "\(prefix).pro.upgrade"
    /// 구독 중인 사람의 졸업가 Pro 평생 (→ LeeoGraduation).
    static let graduateID = "\(prefix).pro.graduate"

    /// Pro 선물 (소모성). 받는 사람은 `proLifetimeID` 를 산 것과 같아진다.
    /// ⚠️ `productIDs` · `tierByProduct` 에 넣지 않는다. 넣으면 선물을 산 사람 자신이 Pro 가 된다.
    static let giftID = "\(prefix).gift.pro"
    /// 개발자 응원하기(팁, 소모성). 작은 것부터. 아무것도 열지 않는다 — 역시 권한 목록에 넣지 않는다.
    static let tipIDs = ["\(prefix).tip.small", "\(prefix).tip.medium", "\(prefix).tip.large"]

    /// 페이월이 불러올 상품. 스토어에 아직 없는 상품은 불러오지 못한 채로 남고, 그 단추만 서지 않는다.
    static let productIDs = [
        plusYearlyID, plusLifetimeID, plusMonthlyID, plusWeeklyID,
        proYearlyID, proLifetimeID, proMonthlyID, proWeeklyID,
        upgradeID, graduateID,
    ]

    /// 상품마다 여는 칸.
    static let tierByProduct: [String: ProTier] = [
        plusWeeklyID: .plus, plusMonthlyID: .plus, plusYearlyID: .plus, plusLifetimeID: .plus,
        proWeeklyID: .pro, proMonthlyID: .pro, proYearlyID: .pro, proLifetimeID: .pro,
        upgradeID: .pro, graduateID: .pro,
    ]

    static var entitlementIDs: Set<String> { Set(tierByProduct.keys) }

    static let lifetimeIDs: Set<String> = [plusLifetimeID, proLifetimeID, upgradeID, graduateID]

    /// 자동 갱신 구독 (구독 졸업을 제안할 대상).
    static let subscriptionIDs: Set<String> = [plusWeeklyID, plusMonthlyID, plusYearlyID,
                                               proWeeklyID, proMonthlyID, proYearlyID]

    static func yearlyID(_ tier: ProTier) -> String { tier == .plus ? plusYearlyID : proYearlyID }
    static func monthlyID(_ tier: ProTier) -> String { tier == .plus ? plusMonthlyID : proMonthlyID }
    static func weeklyID(_ tier: ProTier) -> String { tier == .plus ? plusWeeklyID : proWeeklyID }

    /// 가진 상품 · 앱을 산 사람 · 언제나 평생 패스가 여는 칸. 가장 높은 것.
    static func tier(owning productIDs: Set<String>, grandfathered: Bool, foreverPass: Bool) -> ProTier {
        if grandfathered || foreverPass { return .pro }
        return productIDs.compactMap { tierByProduct[$0] }.max() ?? .free
    }

    static func ownsLifetime(_ tier: ProTier, in productIDs: Set<String>) -> Bool {
        productIDs.contains { lifetimeIDs.contains($0) && tierByProduct[$0] == tier }
    }

    // MARK: 돈을 내고 받은 사람

    /// **유료 다운로드였던 마지막 빌드 번호**(1.0.7 빌드 10). 이 빌드까지 받은 사람은 앱 값을 이미 냈으므로 Pro 로 둔다.
    /// `AppTransaction.originalAppVersion` 은 iOS 에서 처음 받은 빌드의 CFBundleVersion 이다.
    /// ⚠️ 무료로 바꾸기 전에 유료 빌드를 또 냈다면 이 값을 그 번호로 올린다.
    static let lastPaidBuild = "10"

    static func boughtTheApp(originalAppVersion: String) -> Bool {
        originalAppVersion.compare(lastPaidBuild, options: .numeric) != .orderedDescending
    }
}

// MARK: - 권한

/// 말문 Plus · Pro 권한과 무료 한도. 결제 엔진은 LeeoKit 의 LeeoStore 가 맡는다.
/// 화면 없이 도는 퇴근길 모드(Siri · 차량 버튼)도 같은 판정을 써야 해서 앱 전체에 하나만 둔다.
@MainActor
final class MalmunPro: ObservableObject {
    static let shared = MalmunPro()

    /// 퇴근길 모드 무료 장면 수 (하루)
    nonisolated static let freeDriveScenesPerDay = 3
    /// 직접 만들거나 가져온 시나리오 무료 개수
    nonisolated static let freeScenarioLimit = 3
    /// 상황별 회화 중 무료로 여는 분류
    nonisolated static let freeSituationCategories: Set<String> = ["basic", "casual"]

    let store: LeeoStore
    /// 언제나 평생 패스. **팔지는 않는다**(포트폴리오 전체에서 판매를 멈췄다). 이미 산 사람은 Pro 로 연다.
    let foreverPass = LeeoForeverPass(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub")

    /// 지금 쓰는 칸. 화면은 이 값(과 `allows`)만 본다.
    @Published private(set) var tier: ProTier = .free
    @Published private(set) var products: [Product] = []
    @Published private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 구독. 있으면 설정에 '평생으로 바꾸기' 가 선다.
    @Published private(set) var subscription: LeeoGraduation.Subscription?
    @Published private(set) var isWorking = false
    /// 사다가 막혔을 때 화면에 그대로 보일 말.
    @Published private(set) var failureMessage: String?

    /// **유료 칸 상품을 한 번이라도 불러왔는가.** 아니면 아무것도 잠그지 않는다 —
    /// 상품을 만들기 전에 빌드가 나가도 살 수 없는데 막히는 사람이 없게. 한 번 불러온 기기는
    /// 그 뒤 네트워크가 끊겨도 다시 잠근다(값을 기억한다).
    @Published private(set) var plansOnSale = UserDefaults.standard.bool(forKey: MalmunPro.plansOnSaleKey)
    private static let plansOnSaleKey = "pro.plansOnSale"

    /// 띄울 페이월 (ContentView 가 시트로 보여 준다)
    @Published var paywallFeature: ProFeature?
    /// 특정 기능 없이 여는 페이월 (홈의 Pro 버튼)
    @Published var showGeneralPaywall = false
    @Published private(set) var driveScenesToday = 0

    private var observations: [AnyCancellable] = []
    private let driveDayKey = "pro.drive.day"
    private let driveCountKey = "pro.drive.count"

    private init() {
        store = LeeoStore(config: MalmunSpec.paywall!, grandfather: {
            // 유료 다운로드 시절에 받은 사람은 Pro. 실제 App Store 결제만 믿는다 — 샌드박스(TestFlight · 심사)의
            // originalAppVersion 은 늘 "1.0" 이라, 믿으면 모두가 Pro 가 되어 페이월을 시험할 수 없다.
            guard let result = try? await AppTransaction.shared, case .verified(let app) = result,
                  app.environment == .production else { return false }
            return ProEntitlement.boughtTheApp(originalAppVersion: app.originalAppVersion)
        })
        driveScenesToday = currentDriveCount()
        // objectWillChange 는 바뀌기 **직전**에 온다. 다음 차례로 미뤄 새 값을 읽는다.
        observations = [store.objectWillChange.eraseToAnyPublisher(),
                        foreverPass.objectWillChange.eraseToAnyPublisher()].map {
            $0.sink { [weak self] _ in Task { @MainActor in self?.pull() } }
        }
        pull()
    }

    /// Pro 선물하기 엔진. 화면은 이 엔진을 따로 관찰한다(`SettingsView` 의 `GiftRows`).
    var gift: LeeoGiftStore? { store.gift }
    /// 개발자 응원하기 엔진. 상품이 오면 줄 · 카드가 스스로 선다.
    var tipJar: LeeoTipJar? { store.tipJar }

    /// 이 기능을 써도 되는가. 파는 상품이 없으면 막지 않는다.
    func allows(_ feature: ProFeature) -> Bool {
        !plansOnSale || tier >= feature.tier
    }

    func showPaywall(_ feature: ProFeature) {
        paywallFeature = feature
    }

    func ownsLifetime(_ tier: ProTier) -> Bool { ProEntitlement.ownsLifetime(tier, in: ownedProductIDs) }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    // MARK: 상황별 회화 (Plus)

    func isLocked(_ scenario: ConversationScenario) -> Bool {
        guard let category = scenario.category else { return false }
        return isLocked(category: category)
    }

    func isLocked(category: String) -> Bool {
        !Self.freeSituationCategories.contains(category) && !allows(.situations)
    }

    /// 잠긴 시나리오면 페이월을 띄우고 false
    func canOpen(_ scenario: ConversationScenario) -> Bool {
        guard isLocked(scenario) else { return true }
        paywallFeature = .situations
        return false
    }

    // MARK: 내 시나리오 (Plus)

    /// 지금 가진 개수에서 하나 더 만들 수 있는가 (직접 만들기 · 가져오기 모두).
    func canAddScenario(currentCount: Int) -> Bool {
        allows(.scenarios) || currentCount < Self.freeScenarioLimit
    }

    // MARK: 퇴근길 모드 (Pro)

    /// 오늘 무료로 남은 장면 수 (열려 있으면 nil)
    var driveScenesLeft: Int? {
        allows(.commute) ? nil : max(0, Self.freeDriveScenesPerDay - currentDriveCount())
    }

    /// 다음 장면을 들어도 되는지
    func canStartDriveScene() -> Bool {
        allows(.commute) || currentDriveCount() < Self.freeDriveScenesPerDay
    }

    /// 장면 하나를 시작했을 때 (열려 있으면 세지 않는다)
    func countDriveScene() {
        guard !allows(.commute) else { return }
        let count = currentDriveCount() + 1
        UserDefaults.standard.set(Self.dayStamp(), forKey: driveDayKey)
        UserDefaults.standard.set(count, forKey: driveCountKey)
        driveScenesToday = count
    }

    private func currentDriveCount() -> Int {
        guard UserDefaults.standard.string(forKey: driveDayKey) == Self.dayStamp() else { return 0 }
        return UserDefaults.standard.integer(forKey: driveCountKey)
    }

    private static func dayStamp(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    // MARK: 상태 맞추기

    /// 영수증을 다시 읽어 칸을 정한다. 앱이 켜질 때와 활성화될 때마다 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        await foreverPass.refresh()
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: ProEntitlement.subscriptionIDs)
        pull()
    }

    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// 구독 졸업을 제안할 때인가. 6개월째와 갱신 7일 전에 한 번씩. 띄운 쪽이 `markGraduationOffered()` 를 부른다.
    var graduationIsDue: Bool {
        guard let subscription, product(ProEntitlement.graduateID) != nil else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    func markGraduationOffered() { LeeoGraduation.markOffered() }

    // MARK: 사기 / 되찾기

    /// ⚠️ `action` 은 화면의 `@Environment(\.purchase)` 다. 아이패드에서 결제 시트가 엉뚱한 창에 뜨지 않게.
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        await didChangePurchases()
    }

    /// 구독 졸업 평생 · 다른 화면에서 산 뒤.
    func didChangePurchases() async {
        await store.refreshEntitlements()
        subscription = await LeeoGraduation.currentSubscription(among: ProEntitlement.subscriptionIDs)
        pull()
    }

    func restore() async {
        await store.restore()
        await foreverPass.refresh()
        pull()
        if tier == .free, failureMessage == nil {
            failureMessage = String(localized: "이 Apple 계정에서 구매한 기록을 찾지 못했어요.", comment: "Restore found nothing")
        }
    }

    // MARK: -

    private func pull() {
        tier = Self.debugTier ?? ProEntitlement.tier(owning: store.purchasedProductIDs,
                                                     grandfathered: store.isGrandfathered,
                                                     foreverPass: foreverPass.isActive)
        products = store.products
        ownedProductIDs = store.purchasedProductIDs
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
        // 유료 칸 상품이 하나라도 오면 그때부터 판다 (졸업 · 올리기만 온 것은 셈하지 않는다).
        let selling = store.products.contains { ProEntitlement.tierByProduct[$0.id] != nil
            && $0.id != ProEntitlement.graduateID && $0.id != ProEntitlement.upgradeID }
        if selling, !plansOnSale {
            plansOnSale = true
            UserDefaults.standard.set(true, forKey: Self.plansOnSaleKey)
        }
    }

    /// 개발 빌드는 잠금 없이 쓴다(Pro). `-paywall` 로 켜면 실제 잠금 · 구매를 시험한다.
    private static var debugTier: ProTier? {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-paywall") ? nil : .pro
        #else
        return nil
        #endif
    }
}
