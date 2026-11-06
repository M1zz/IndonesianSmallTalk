# 말문 요금제 (무료 · Plus · Pro)

1.0.7(빌드 10)까지는 유료 다운로드였다. 다음 버전부터 **무료 다운로드 + 무료 · Plus · Pro** 다.

## 무엇이 어느 칸인가

| 기능 | 무료 | Plus | Pro |
|---|---|---|---|
| 배울 언어 6개 | ✓ | ✓ | ✓ |
| 상황별 회화 | 기본 · 일상 | 53개 전체 | 53개 전체 |
| 하루 코스 · 주간 시간표 · 스몰토크 | ✓ | ✓ | ✓ |
| 발음 연습 · 스크립트 · 연습 기록 | ✓ | ✓ | ✓ |
| 내 문장 · 단어 카드 · 문장 키보드 | ✓ | ✓ | ✓ |
| 직접 만든 시나리오 · 가져오기 | 3개 | 무제한 | 무제한 |
| 퇴근길 모드 | 하루 3장면 | 하루 3장면 | 무제한 |
| AI 시나리오 만들기 | – | – | ✓ |
| iCloud로 친구와 나누기 | – | – | ✓ |

- 원본은 `Models/MalmunPro.swift` 한 곳(`ProTier` · `ProFeature.tier` · `PlanComparisonRow`). 페이월 · 잠긴 자리가 모두 거기를 읽는다.
- 퇴근길 장면은 **시작할 때** 하나로 센다. 한도에 닿으면 소리로 알려 주고 멈추며, 화면이 떠 있으면(아니면 다음에 앱을 열 때) Pro 페이월이 뜬다.
- 내 시나리오 한도는 **새로 만들 때만** 막는다. 예전에 만든 것이 3개를 넘어도 보고 · 연습하고 · 고치고 · 지운다. 친구가 나눠 준 시나리오 보기, 공유 해제도 늘 열려 있다.
- 잠긴 상황별 회화 분류는 퇴근길 · 발음 연습 추천 · 대본 고르기에서도 빠진다.
- **스토어에서 유료 칸 상품을 한 번도 못 불러온 기기는 아무것도 잠그지 않는다**(`plansOnSale`). 한 번 불러오면 그 뒤로는 잠근다.
- 팁 · 선물은 그대로. 팁은 아무것도 열지 않고, 응원 부탁은 Pro 에게만 한다. 선물은 Pro 평생을 연다.
- 언제나 평생 패스는 팔지 않는다(포트폴리오 전체에서 판매 중단). 이미 산 사람은 Pro.

## 이미 산 사람

- `AppTransaction.originalAppVersion` ≤ **"10"**(유료 다운로드 마지막 빌드)이면 Pro (`ProEntitlement.lastPaidBuild`). 실제 App Store 결제(environment == .production)만 믿는다.
- ⚠️ 무료로 바꾸기 전에 유료 빌드를 또 내면 이 값을 그 번호로 올린다.
- 예전 상품 `…pro.yearly`(Pro 연) · `…pro.lifetime`(Pro 평생)은 그대로 이어 쓴다. 구독자 · 구매자 · 선물받은 사람은 그대로 Pro.

## 상품 (구독 그룹 `Malmun Pro`, Pro 가 단계 1 · Plus 가 단계 2)

| 상품 ID | 종류 | 기간 | 원화 | 달러 |
|---|---|---|---|---|
| `com.devkoan.IndonesianSmallTalk.plus.weekly` | 자동 갱신 | 1주 | ₩2,200 | $1.49 |
| `com.devkoan.IndonesianSmallTalk.plus.monthly` | 자동 갱신 | 1개월 | ₩5,500 | $3.49 |
| `com.devkoan.IndonesianSmallTalk.plus.yearly` | 자동 갱신 | 1년 (첫 해 반값) | ₩14,000 | $9.99 |
| `com.devkoan.IndonesianSmallTalk.plus.lifetime` | 비소모성 | – | ₩43,000 | $29.99 |
| `com.devkoan.IndonesianSmallTalk.pro.weekly` | 자동 갱신 | 1주 | ₩3,300 | $1.99 |
| `com.devkoan.IndonesianSmallTalk.pro.monthly` | 자동 갱신 | 1개월 | ₩7,700 | $4.99 |
| `com.devkoan.IndonesianSmallTalk.pro.yearly` (기존) | 자동 갱신 | 1년 (첫 해 반값) | ₩22,000 | $14.99 |
| `com.devkoan.IndonesianSmallTalk.pro.lifetime` (기존) | 비소모성 | – | ₩65,000 | $44.99 |
| `com.devkoan.IndonesianSmallTalk.pro.upgrade` | 비소모성 (Plus 평생 → Pro 평생) | – | ₩22,000 | $14.99 |
| `com.devkoan.IndonesianSmallTalk.pro.graduate` | 비소모성 (구독 졸업 Pro 평생) | – | ₩43,000 | $29.99 |

`IndonesianSmallTalk/Products.storekit` 에 모두 있다(스킴 Run 에 연결됨). Xcode 에서 ⌘R 할 때 실행 인자 `-paywall` 을 켜면 잠금과 구매를 시험한다 — 없으면 DEBUG 는 Pro 로 연다.
`-ScreenshotScene paywall` 로 페이월만 띄울 수 있다.

## 페이월이 뜨는 곳

- 잠긴 상황별 회화(홈) → Plus 칸 앞
- 퇴근길 모드 그날 4번째 장면 → Pro 칸 앞
- 내 시나리오 · 가져온 대화를 4번째로 저장 → Plus (사고 돌아오면 저장을 마친다)
- AI 시나리오 만들기 · 친구와 나누기(만들기 화면의 토글, 카드의 공유) → Pro
- 홈의 Pro 단추 · 설정 ▸ 말문 Plus · Pro
- 구독 6개월째 · 갱신 7일 전: 구독 졸업 제안(`LeeoGraduationOfferView`, 산 뒤 구독 관리 화면 안내). 설정의 '평생으로 바꾸기' 는 구독 중이면 늘 보인다.
