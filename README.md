# 사노라면 — Indonesian Small Talk

🇮🇩 인도네시아어 일상 스몰토크를 트리형 대화로 연습하는 iOS 앱.

## 지원 페이지

**👉 https://m1zz.github.io/IndonesianSmallTalk/**

문의·개인정보 처리방침·자주 묻는 질문은 위 지원 페이지를 참고해주세요.

## 주요 기능

- **시나리오 트리 연습** — 분기형 대화, 긍/부정 폴라리티에 따른 점수와 코칭 팁
- **텍스트·음성 두 가지 모드** — 텍스트 모드는 자동 TTS, 음성 모드는 STT 매칭
- **내 표현 라이브러리** — 새로 배운 표현 저장·수정·따라말하기
- **친구와 함께 보기** — CloudKit (`CKShare`) 기반 양방향 동기화 + 사일런트 푸시
- **표현 키보드 익스텐션** — 한국어 보고 탭하면 인도네시아어 입력
- **사용자 시나리오/응답 직접 추가** — 트리에 내 답변·새 스몰토크 추가
- **스터디 트래킹** — 자주 연습한 표현 자동 정렬

## 빌드

- Xcode 15+, iOS 17.0+ 타겟
- 시뮬레이터에서 빌드만 하려면 추가 설정 불필요
- 실기기 / CloudKit / 키보드 동작에는 다음 Capabilities 가 필요:
  - **iCloud** (CloudKit)
  - **App Groups** (`group.com.devkoan.IndonesianSmallTalk`)
  - **Push Notifications**
  - **Background Modes** → Remote notifications

## 구조

- `IndonesianSmallTalk/` — 메인 앱 (SwiftUI)
- `KeyboardExtension/` — 표현 키보드 익스텐션 (UIKit)
- `scripts/make_app_icon.py` — 아이콘 빌드 스크립트 (Pillow)
- `docs/` — GitHub Pages 지원 페이지

## 라이선스

개인 학습 프로젝트.
