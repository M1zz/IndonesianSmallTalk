# CarPlay 에 말문 아이콘 띄우기

퇴근길 모드는 **지금도 차에서 그대로 쓴다.** 블루투스나 CarPlay 로 연결하면
차 화면의 '지금 재생'에 지금 문장이 뜨고, 운전대 버튼(다음/이전/재생)으로 조작된다.

CarPlay 홈 화면에 **말문 아이콘과 목록 화면**(`Drive/CarPlaySceneDelegate.swift`)을 띄우려면
Apple 의 CarPlay 오디오 권한이 필요하다. 코드와 Info.plist 의 CarPlay scene 설정은 이미 들어가 있다.

## 사람이 할 일

1. https://developer.apple.com/contact/carplay/ 에서 신청한다.
   - 분류: **Audio** (말소리 학습 콘텐츠를 재생하는 오디오 앱)
   - 설명 예: "Hands-free language practice for commuting. The app plays spoken phrases and answers; the driver repeats aloud. No screen interaction while driving."
2. 승인되면 developer.apple.com ▸ Identifiers ▸ `com.devkoan.IndonesianSmallTalk` 에 CarPlay Audio 가 켜진다.
3. `IndonesianSmallTalk/IndonesianSmallTalk.entitlements` 에 한 줄을 더한다.

   ```xml
   <key>com.apple.developer.carplay-audio</key>
   <true/>
   ```

   승인 전에 넣으면 서명이 실패하니 **승인 뒤에만** 넣는다.
4. Xcode ▸ Window ▸ Devices 의 CarPlay 시뮬레이터(I/O ▸ External Displays ▸ CarPlay)로 목록 → 지금 재생을 확인한다.

## 지금 들어 있는 것

- `Info.plist`: `UIBackgroundModes` 에 `audio`, `CPTemplateApplicationSceneSessionRoleApplication` scene
- `AppDelegate`: CarPlay 역할이면 `CarPlaySceneDelegate`
- `DriveSession`: `.playback` + `.spokenAudio` (내비 안내가 나오면 잠깐 멈췄다가 이어 감), 지금 재생 정보, 원격 명령
- `DriveIntents`: Siri·단축어 "퇴근길 연습 시작/멈추기" (`AudioPlaybackIntent`, 앱을 열지 않음)
