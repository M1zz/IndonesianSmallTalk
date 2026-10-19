import Foundation
import LeeoKit

// MARK: - 원격 킬스위치
//
// 심사 없이 문제 기능을 끄는 장치. FeedbackHub 의 RemoteFlags 레코드
// (recordName `flags_com.devkoan.IndonesianSmallTalk`)에 필드를 Int64 로 두고 0 이면 꺼진다.
// 조회에 실패하거나 필드가 없으면 켜진 채로 동작한다 — 킬스위치가 장애 원인이 되면 안 된다.
//
// ⚠️ rawValue 가 CloudKit 필드명이다. 바꾸면 대시보드에서 꺼도 앱은 켠 채로 돈다.

enum MalmunFlag: String, LeeoRemoteFlag, CaseIterable {
    /// 퇴근길 모드 목소리 조작 — 운전 중 마이크·음성 인식을 쓰는 기능.
    /// 오디오 세션이 꼬이거나 심사 문제가 생기면 이것만 끄고, 소리·운전대 버튼·Siri 로 하는 기본 흐름은 둔다.
    case driveVoice
}
