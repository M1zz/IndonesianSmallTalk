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

## 가격 (추천)

| 상품 | 상품 ID | 유형 | 추천 가격 | 무료 체험 |
|---|---|---|---|---|
| 말문 Pro 연간 | `com.devkoan.IndonesianSmallTalk.pro.yearly` | 자동 갱신 구독 · 1년 (그룹 `Malmun Pro`) | **$19.99 / 년** | 1주 |
| 말문 Pro 평생 | `com.devkoan.IndonesianSmallTalk.pro.lifetime` | 비소모성 (한 번 결제) | **$39.99** | — |

- **근거**: 큰 언어 앱 연간 구독은 대략 $80~$100 (Duolingo Super·Speak·Babbel). 말문 Pro 는 퇴근길 모드·상황별 회화 두 가지만 여는 1인 앱이라 그 4분의 1 수준으로 잡았다.
- **평생 = 연간의 2배**: 2년 넘게 쓸 사람은 평생을, 대부분은 연간을 고르게 한다.
- **다른 안**: 낮게 $14.99 / $29.99 (전환을 먼저 보고 싶을 때), 높게 $29.99 / $59.99 (상황별 회화를 더 늘린 뒤).
- 다른 나라 가격은 App Store Connect 가 미국 가격 기준으로 자동 환산한다. 한국만 따로 정하고 싶으면 그 나라 가격을 직접 고친다.
- `IndonesianSmallTalk/Products.storekit` 의 시험 가격도 이 숫자로 맞춰 두었다 (Xcode 시험용일 뿐, 실제 가격은 App Store Connect 가 정한다).

## 내가 할 일

| # | 어디서 | 할 일 | 비고 |
|---|---|---|---|
| 1 | App Store Connect ▸ 비즈니스 | 유료 앱 계약·세금·은행 정보가 '활성'인지 확인 | 비활성이면 상품이 앱에 안 뜬다 |
| 2 | 앱 ▸ 구독 | 구독 그룹 `Malmun Pro` 만들기 → 그 안에 `…pro.yearly` (1년) | ID 는 코드와 글자 하나까지 같아야 한다 |
| 3 | 앱 ▸ 구독 ▸ 연간 | 가격 **$19.99**, 도입 혜택 **1주 무료 체험** | |
| 4 | 앱 ▸ 인앱 구매 | 비소모성 `…pro.lifetime`, 가격 **$39.99** | |
| 5 | 두 상품 모두 | 표시 이름·설명 6개 언어 (Products.storekit 의 문구를 그대로 써도 됨), 심사 정보 ▸ 스크린샷: 연간 = `docs/screenshots/iap-review/en-US/1-pro-yearly.png`, 평생 = `…/en-US/2-pro-lifetime.png` (한국어판은 `ko/`) | 가격을 다르게 정했으면 `scripts/capture_paywall_screenshot.sh <UDID> '$가격' '$가격'` 로 다시 찍는다 |
| 6 | 구독 그룹 | 그룹 표시 이름 현지화 (예: 말문 Pro / Malmun Pro) | |
| 7 | 앱 ▸ 앱 개인정보 | 아래 표대로 수집 항목 고치기 | 이번에 익명 통계가 새로 생겼다 |
| 8 | 버전 제출 | 이번 버전 심사에 두 상품을 함께 선택 | 처음 파는 상품은 버전과 같이 심사받는다 |
| 9 | (기기에서 처음 빌드할 때) | Xcode 자동 서명이 App ID 에 `iCloud.com.Ysoup.FeedbackHub` 컨테이너를 붙이는지 확인. 실패하면 developer.apple.com ▸ Identifiers ▸ `com.devkoan.IndonesianSmallTalk` ▸ iCloud ▸ 컨테이너에 추가 | 다른 앱들과 같은 팀(QGAQ3AY3R3)이라 보통 저절로 된다 |

### 앱 개인정보 라벨 (7번)

| 데이터 | 수집 | 사용자와 연결 | 추적 | 목적 |
|---|---|---|---|---|
| 사용 데이터 ▸ 제품 상호 작용 (실행·사용 횟수) | 예 | 아니요 | 아니요 | 분석 |
| 진단 ▸ 충돌 데이터 · 성능 데이터 | 예 | 아니요 | 아니요 | 앱 기능 |
| 연락처 정보 ▸ 이메일 (피드백에 적은 경우만) | 예 | 예 | 아니요 | 고객 지원 |
| 사용자 콘텐츠 ▸ 고객 지원 (피드백 내용) | 예 | 아니요 | 아니요 | 고객 지원 |
| 구매 내역 | 아니요 (Apple 이 처리) | | | |

## 나중에

- 페이월 노출·구매 퍼널은 허브(FeedbackHubViewer)에서 `paywall_shown → purchase_started → purchase_completed` 로 보인다 (LeeoUsageAnalytics 가 스스로 보낸다).
- 원격 킬스위치: FeedbackHub ▸ RemoteFlags ▸ `flags_com.devkoan.IndonesianSmallTalk` 에 `driveVoice` 를 0 으로 두면 퇴근길 목소리 조작만 꺼진다.
