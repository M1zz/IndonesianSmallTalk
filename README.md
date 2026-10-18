# 말문 — Malmun

한 줄씩 트이는 외국어 회화. 갈래 있는 대화로 연습하고, 차에서는 귀로 연습하는 iOS 앱.
(예전 이름: 사노라면 — 인도네시아어 전용 스몰토크 앱. 번들 ID 는 그대로라 기존 사용자는 업데이트로 이어진다.
같은 구조였던 스픽플로우 앱의 상황별 회화·발음 연습·대본 보기·대화 가져오기·연습 기록을 여기로 옮겼다.)

## 지원 페이지

**👉 https://m1zz.github.io/IndonesianSmallTalk/**

## 언어

- **배우는 언어 6개**: 인도네시아어 · 영어 · 일본어 · 중국어 · 스페인어 · 한국어 (홈 맨 위 국기로 바꾼다)
- **화면 언어 6개**: ko(원문) · en · ja · zh-Hans · es · id — `Resources/Localizable.xcstrings`, `InfoPlist.xcstrings`, `AppShortcuts.xcstrings`
- 화면 언어와 같은 언어는 배울 언어 목록에서 빠진다. 내 표현·내 시나리오·단어장·공유 시나리오는 언어별로 따로 보인다.

## 주요 기능

- **시나리오 트리 연습**: 분기형 대화, 긍/부정 폴라리티 점수, 코치 팁. 텍스트·음성 모드
- **콘텐츠**: 인도네시아어는 스몰토크 5개 + 하루 코스 3개(18장면) + 출장 100단어. 6개 언어 모두 상황별 회화 53개
- **퇴근길 모드** (`Drive/`): 화면 없이 소리로 진행. 뜻 → 딩 → 말해 볼 시간 → 정답(천천히·보통)
  - 차량 버튼: 다음 곡 = 다음 문장, 이전 곡 = 한 번 더, 재생/멈춤
  - 폰을 블루투스·CarPlay 로 차에 연결하면 소리는 차 스피커로, 지금 문장은 차 화면 '지금 재생'에 나온다
  - 목소리 조작(`Drive/DriveVoice.swift`): 말해 볼 차례에만 폰 마이크로 듣고(기기 안 인식), 맞으면 "좋아요",
    "다음 / 다시 / 천천히 / 빠르게 / 다음 장면 / 그만" 을 화면 언어로 알아듣는다. 소리는 A2DP 로 차에, 마이크는 폰 것
  - Siri: "말문 퇴근길 연습 시작 / 계속 / 다음 / 다시 / 연습 멈춰", 단축어 자동화(CarPlay·블루투스 연결 시)
  - 퇴근길 모드를 처음 열면 차에서 쓰는 법(자동 시작 설정·목소리 명령)을 한 번 보여 준다
  - CarPlay 전용 화면(차 화면 아이콘)은 일부러 두지 않는다 — Apple 권한이 필요하고, 폰에서 재생하면 충분하다
- **연습 도구**: 발음 연습(점수·낱말 표시), 대본 보기(메신저 모양), 대화 가져오기(붙여넣기), 연습 기록(연속 일수)
- **내 표현 · 단어장 · 표현 키보드 · 친구와 함께 보기(CloudKit) · AI 시나리오 생성**

## 콘텐츠 파일

- `Resources/Content/situations.<언어>.json`: 상황별 회화 (모든 화면 언어의 뜻 포함)
- `Resources/Content/translations.<언어>.json`: 한국어로만 쓰인 인도네시아어 기본 콘텐츠의 다른 화면 언어 번역.
  키 규칙은 `ContentKey`, 원문 뽑기는 `scripts/export_content_strings.swift`

## 빌드

- Xcode 15+, iOS 17.0+ 타겟
- 새 파일은 `python3 scripts/pbx_add.py <경로>` 로 프로젝트에 등록
- 아이콘: `python3 scripts/make_app_icon.py` (AppIcon + 앱 안 로고 BrandMark)
- 실기기 / CloudKit / 키보드 동작에 필요한 Capabilities: iCloud(CloudKit), App Groups(`group.com.devkoan.IndonesianSmallTalk`), Push Notifications, Background Modes(Remote notifications, Audio)

## 구조

- `IndonesianSmallTalk/` 메인 앱 (SwiftUI): `App/` `Models/` `Stores/` `Services/` `Views/` `Drive/` `Resources/`
- `KeyboardExtension/` 표현 키보드 (UIKit)
- `docs/` GitHub Pages 지원 페이지
