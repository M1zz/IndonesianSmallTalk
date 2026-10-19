import Foundation
import LeeoKit

/// LeeoKit 계약 — 말문의 이름·연락처·정책 링크·수익모델을 한곳에 둔다.
///
/// 수익모델(부분 유료화): 기본 스몰토크·하루 코스·내 표현·단어장·키보드·발음 연습은 모두 무료.
/// 말문 Pro 는 두 가지를 연다 — 퇴근길 모드 무제한(무료는 하루 3장면), 상황별 회화 전체(무료는 기본·일상 대화).
/// 상품은 연간 구독(체험은 App Store Connect 에서 설정) + 평생 구매.
///
/// 피드백·사용 통계 허브(FeedbackHub)는 아직 켜지 않았다 — 켜기 전에 iCloud 권한에
/// iCloud.com.Ysoup.FeedbackHub 를 넣어야 한다 (권한 없이 CKContainer 를 만들면 앱이 죽는다).
/// 그래서 LeeoKit.bootstrap 도 아직 부르지 않는다.
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
}
