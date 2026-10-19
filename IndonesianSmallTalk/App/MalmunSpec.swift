import Foundation
import LeeoKit

/// LeeoKit 계약 — 말문의 이름·연락처·정책 링크·수익모델을 한곳에 둔다.
///
/// 수익모델(부분 유료화): 기본 스몰토크·하루 코스·내 표현·단어장·키보드·발음 연습은 모두 무료.
/// 말문 Pro 는 두 가지를 연다 — 퇴근길 모드 무제한(무료는 하루 3장면), 상황별 회화 전체(무료는 기본·일상 대화).
/// 상품은 연간 구독(체험은 App Store Connect 에서 설정) + 평생 구매.
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

    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/IndonesianSmallTalk/#privacy")!,
        supportURL: URL(string: "https://m1zz.github.io/IndonesianSmallTalk/")!
    )

    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: [MalmunPro.yearlyID, MalmunPro.lifetimeID],
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            gate: LeeoGatePolicy(
                freeLimits: [ProFeature.commute.rawValue: MalmunPro.freeDriveScenesPerDay],
                proOnly: [ProFeature.situations.rawValue],
                warnWhenRemaining: 1
            )
        )
    )

    /// 익명 사용 통계 → FeedbackHub(CloudKit). 부트스트랩이 하루 한 번 app_open 과 스냅샷을 보낸다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: MalmunSpec.self)
}
