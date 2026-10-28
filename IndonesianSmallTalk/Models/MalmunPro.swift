import Combine
import Foundation
import LeeoKit

// MARK: - Pro feature

/// 무료 사용자가 부딪히는 잠금 기능. 페이월은 "방금 누른 그것"을 앞세워 보여 준다.
enum ProFeature: String, Identifiable, CaseIterable, LeeoProFeature {
    case commute     // 퇴근길 모드 — 하루 무료 장면 수를 넘었을 때
    case situations  // 상황별 회화 — 기본·일상 대화 밖의 분류

    var id: String { rawValue }

    var leeoTitle: String {
        switch self {
        case .commute: return String(localized: "퇴근길 모드 무제한")
        case .situations: return String(localized: "상황별 회화 전체")
        }
    }

    var leeoDetail: String {
        switch self {
        case .commute: return String(localized: "하루 장면 수 제한 없이, 출퇴근 내내 귀로 연습해요.")
        case .situations: return String(localized: "공항·숙소·식당·교통·쇼핑·관광·긴급 상황까지, 배우는 모든 언어로 열려요.")
        }
    }

    var leeoIcon: String {
        switch self {
        case .commute: return "car.fill"
        case .situations: return "map.fill"
        }
    }
}

// MARK: - Pro access

/// 말문 Pro 권한과 무료 한도. 결제 엔진은 LeeoKit 의 LeeoStore 가 맡는다.
/// 화면 없이 도는 퇴근길 모드(Siri·차량 버튼)도 같은 판정을 써야 해서 앱 전체에 하나만 둔다.
@MainActor
final class MalmunPro: ObservableObject {
    static let shared = MalmunPro()

    nonisolated static let yearlyID = "com.devkoan.IndonesianSmallTalk.pro.yearly"
    nonisolated static let lifetimeID = "com.devkoan.IndonesianSmallTalk.pro.lifetime"
    /// Pro 선물 (소모성). 받는 사람은 `lifetimeID` 를 산 것과 같아진다.
    /// ⚠️ 판매 목록(productIDs)에 넣지 않는다. 넣으면 선물을 산 사람 자신이 Pro 가 된다.
    nonisolated static let giftID = "com.devkoan.IndonesianSmallTalk.gift.pro"

    /// 퇴근길 모드 무료 장면 수 (하루)
    nonisolated static let freeDriveScenesPerDay = 3
    /// 상황별 회화 중 무료로 여는 분류
    nonisolated static let freeSituationCategories: Set<String> = ["basic", "casual"]

    let store: LeeoStore

    /// 띄울 페이월 (ContentView 가 시트로 보여 준다)
    @Published var paywallFeature: ProFeature?
    /// 특정 기능 없이 여는 페이월 (홈의 Pro 버튼)
    @Published var showGeneralPaywall = false
    @Published private(set) var driveScenesToday = 0

    private var storeChanges: AnyCancellable?
    private let driveDayKey = "pro.drive.day"
    private let driveCountKey = "pro.drive.count"

    private init() {
        store = LeeoStore(config: MalmunSpec.paywall!, unlockOverride: {
            #if DEBUG
            // 개발 빌드는 잠금 없이 쓴다. -paywall 로 켜면 실제 잠금·구매를 시험한다.
            return ProcessInfo.processInfo.arguments.contains("-paywall") ? nil : true
            #else
            return nil
            #endif
        })
        driveScenesToday = currentDriveCount()
        // 구매·복원·환불이 반영되면 이 객체를 보는 화면도 다시 그린다.
        storeChanges = store.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    var hasPro: Bool { store.hasPro }
    /// Pro 선물하기 엔진. 상품은 앱이 뜬 뒤에 오고 이 객체는 그 변화를 알리지 않으므로,
    /// 화면은 이 엔진을 따로 관찰한다(`SettingsView` 의 `GiftRows`).
    var gift: LeeoGiftStore? { store.gift }

    // MARK: 상황별 회화

    func isLocked(_ scenario: ConversationScenario) -> Bool {
        guard let category = scenario.category else { return false }
        return isLocked(category: category)
    }

    func isLocked(category: String) -> Bool {
        !Self.freeSituationCategories.contains(category) && !store.gate.allows(ProFeature.situations.rawValue)
    }

    /// 잠긴 시나리오면 페이월을 띄우고 false
    func canOpen(_ scenario: ConversationScenario) -> Bool {
        guard isLocked(scenario) else { return true }
        paywallFeature = .situations
        return false
    }

    // MARK: 퇴근길 모드

    /// 오늘 무료로 남은 장면 수 (Pro 면 nil)
    var driveScenesLeft: Int? {
        store.gate.remaining(ProFeature.commute.rawValue, current: currentDriveCount())
    }

    /// 다음 장면을 들어도 되는지
    func canStartDriveScene() -> Bool {
        store.gate.evaluate(ProFeature.commute.rawValue, current: currentDriveCount()).isAllowed
    }

    /// 장면 하나를 다 들었을 때 (Pro 면 세지 않는다)
    func countDriveScene() {
        guard !store.gate.isUnlocked else { return }
        let count = currentDriveCount() + 1
        UserDefaults.standard.set(Self.dayStamp(), forKey: driveDayKey)
        UserDefaults.standard.set(count, forKey: driveCountKey)
        driveScenesToday = count
    }

    func showPaywall(_ feature: ProFeature) {
        paywallFeature = feature
    }

    private func currentDriveCount() -> Int {
        guard UserDefaults.standard.string(forKey: driveDayKey) == Self.dayStamp() else { return 0 }
        return UserDefaults.standard.integer(forKey: driveCountKey)
    }

    private static func dayStamp(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    /// 페이월 혜택 목록
    static var paywallFeatures: [String] {
        [String(localized: "퇴근길 모드 무제한 — 하루 장면 수 제한 없음"),
         String(localized: "상황별 회화 전체 — 공항·숙소·식당·교통·쇼핑·관광·긴급"),
         String(localized: "배우는 6개 언어 모두에 적용"),
         String(localized: "한 번 사면 iPhone·iPad 어디서나")]
    }
}
