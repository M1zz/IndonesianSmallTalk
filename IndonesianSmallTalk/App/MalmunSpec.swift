import Foundation
import LeeoKit

/// LeeoKit 계약 — 말문의 이름·연락처·정책 링크·수익모델을 한곳에 둔다.
///
/// 수익모델: 무료 다운로드 + 무료 · Plus · Pro (1.0.7 까지는 유료 다운로드였다 — 그때 받은 사람은 Pro).
/// Plus 는 상황별 회화 전체 · 내 시나리오 무제한, Pro 는 거기에 퇴근길 모드 무제한 · AI 시나리오 · 친구와 나누기.
/// 칸마다 주 · 월 · 연 구독과 평생. 칸과 상품의 원본은 Models/MalmunPro.swift.
///
/// 피드백·익명 사용 통계·크래시 진단·원격 킬스위치는 공용 허브(FeedbackHub)로 간다 — appIdentifier(번들 ID)로 앱을 구분.
/// ⚠️ 그 iCloud 컨테이너 권한이 IndonesianSmallTalk.entitlements 에 있다. 빼면 CKContainer 를 만드는 순간 앱이 죽는다.
/// (친구와 함께 보기는 따로 iCloud.com.devkoan.IndonesianSmallTalk 컨테이너를 쓴다 — CloudKitService)
enum MalmunSpec: LeeoAppSpec {
    static let appName = "Malmun"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.devkoan.IndonesianSmallTalk"
    )

    /// 백업 금고(LeeoVault)가 함께 담는 앱 그룹.
    static let appGroups = ["group.com.devkoan.IndonesianSmallTalk"]

    /// 정책·지원 페이지는 앱 화면 언어의 페이지로 연다 (docs/ — 한국어는 맨 위, 나머지는 <언어 코드>/).
    static let legal: LeeoLegalConfig = {
        let base = "https://m1zz.github.io/IndonesianSmallTalk/"
        let folder = AppLanguage.native == .korean ? "" : "\(AppLanguage.native.rawValue)/"
        return LeeoLegalConfig(
            privacyURL: URL(string: base + folder + "privacy.html")!,
            supportURL: URL(string: base + folder + "support.html")!
        )
    }()

    /// 무료 · Plus · Pro. 칸마다 주 · 월 · 연 구독과 평생 (→ Models/MalmunPro.swift).
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: ProEntitlement.productIDs,
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            entitlementIDs: ProEntitlement.entitlementIDs,
            // 칸(Plus · Pro)마다 무엇이 열리는지는 `ProFeature.tier` 가 정한다. 여기는 한도의 선언일 뿐이다.
            gate: LeeoGatePolicy(
                freeLimits: [ProFeature.commute.rawValue: MalmunPro.freeDriveScenesPerDay,
                             ProFeature.scenarios.rawValue: MalmunPro.freeScenarioLimit],
                proOnly: [ProFeature.situations.rawValue, ProFeature.aiScenario.rawValue, ProFeature.share.rawValue],
                warnWhenRemaining: 1
            ),
            // Pro 선물하기. 보내는 사람은 소모성 선물 상품을 사고, 받는 사람은 Pro 평생을 산 것과 같아진다.
            // 선물 기록은 피드백과 같은 허브 컨테이너의 공개 DB 에 둔다. entitlements 에 이미 있다.
            // ⚠️ 선물 상품은 productIDs · entitlementIDs 에 넣지 않는다. 넣으면 선물을 산 사람이 Pro 가 된다.
            gift: LeeoGiftConfig(
                productID: ProEntitlement.giftID,
                grantsProductID: ProEntitlement.proLifetimeID,
                containerIdentifier: "iCloud.com.Ysoup.FeedbackHub"
            ),
            // 개발자 응원하기(팁). 소모성이고 아무것도 열지 않는다. 작은 것부터.
            // ⚠️ 팁 상품도 productIDs · entitlementIDs 에 넣지 않는다. 넣으면 낸 사람이 Pro 가 된다.
            tipJar: LeeoTipJarConfig(productIDs: ProEntitlement.tipIDs)
        )
    )

    /// 익명 사용 통계 → FeedbackHub(CloudKit). 부트스트랩이 하루 한 번 app_open 과 스냅샷을 보낸다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: MalmunSpec.self)
}
