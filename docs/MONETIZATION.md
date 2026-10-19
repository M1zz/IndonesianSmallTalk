# 말문 부분 유료화 (말문 Pro)

## 무엇이 무료이고 무엇이 Pro 인가

| | 무료 | Pro |
|---|---|---|
| 스몰토크·하루 코스(인도네시아어) | 전부 | |
| 상황별 회화 (6개 언어) | 기본 · 일상 대화 | 공항 · 숙소 · 식당 · 교통 · 쇼핑 · 관광 · 긴급 |
| 퇴근길 모드 | 하루 3장면 | 무제한 |
| 내 표현 · 단어장 · 키보드 · 발음 연습 · 대본 · 가져오기 · AI 생성 | 전부 | |

- 퇴근길 장면은 **시작할 때** 하나로 센다(끝나기 직전에 건너뛰어도 한 장면). 같은 장면을 다시 들으면 세지 않는다. 날짜가 바뀌면 다시 3장면.
- 한도에 닿으면 소리로 알려 주고 멈춘다. 화면이 떠 있으면 페이월이 뜬다.
- 잠긴 분류는 퇴근길 '상황별 회화'·발음 연습 추천 문장·대본 고르기에서도 빠진다.
- 기존 사용자에게서 빼앗는 기능은 없다 (잠긴 두 기능은 이번 버전에 새로 생긴 것).

## 코드

- `App/MalmunSpec.swift` — LeeoKit 계약. `monetization = .freemiumSubscription(...)`, 게이트 키 `commute`(무료 3) · `situations`(Pro 전용)
- `Models/MalmunPro.swift` — `MalmunPro.shared`: LeeoStore(구매·복원·권한), 무료 한도, 페이월 띄우기
- 페이월 화면은 LeeoKit `LeeoPaywallView` (6개 언어 내장, 구독 기간·약관·개인정보 링크·복원 포함). `ContentView` 에서 시트로 띄운다.
- DEBUG 빌드는 잠금 없이 동작한다. 잠금·구매를 시험하려면 실행 인자 `-paywall`.
- `IndonesianSmallTalk/Products.storekit` — Xcode 에서 실행하면 이 파일로 가짜 구매를 시험한다 (가격은 시험용 숫자일 뿐).

## 사람이 할 일 (App Store Connect)

1. **유료 앱 계약**(Paid Apps Agreement)·세금·은행 정보가 활성인지 확인
2. 인앱 구매 만들기 — ID 는 코드와 똑같아야 한다
   - 구독 그룹 `Malmun Pro` ▸ 자동 갱신 구독 `com.devkoan.IndonesianSmallTalk.pro.yearly` (1년)
     - 도입 혜택: 1주 무료 체험 (선택)
   - 비소모성 `com.devkoan.IndonesianSmallTalk.pro.lifetime`
3. **가격** 정하기 (두 상품 모두)
4. 상품마다 표시 이름·설명을 6개 언어로 (Products.storekit 의 문구를 그대로 써도 된다), 심사용 스크린샷 1장
5. 앱 버전 심사 제출 때 두 상품을 함께 선택
6. 앱 개인정보 라벨: 구매 기록은 Apple 이 처리 — 앱이 따로 모으지 않음

## 나중에

- 피드백·사용 통계 허브(LeeoKit FeedbackHub)를 켜려면 iCloud 권한에 `iCloud.com.Ysoup.FeedbackHub` 를 먼저 넣고 `LeeoKit.bootstrap(MalmunSpec.self)` 를 부른다.
- 페이월 노출·구매 퍼널을 보려면 Spec 에 `analytics` 싱크를 넣는다.
