import Foundation

/// App Group UserDefaults 로 메인 앱과 키보드 익스텐션이 공유하는 설정.
/// 키보드가 어느 방향으로 입력하는지.
/// - kor2ind: 뜻(화면 언어)을 보고 탭 → 배우는 언어 입력 (이름은 예전 저장값과 맞추려고 그대로 둔다)
/// - ind2kor: 배우는 언어를 보고 탭 → 뜻 입력
enum InputDirection: String, Codable {
    case kor2ind
    case ind2kor

    var symbol: String {
        switch self {
        case .kor2ind: return "\(AppLanguage.native.flag) → \(AppLanguage.learning.flag)"
        case .ind2kor: return "\(AppLanguage.learning.flag) → \(AppLanguage.native.flag)"
        }
    }

    var toggled: InputDirection {
        self == .kor2ind ? .ind2kor : .kor2ind
    }
}

enum KeyboardSettings {
    static let suite = "group.com.devkoan.IndonesianSmallTalk"

    private enum Keys {
        static let slangEnabled = "slangEnabled"
        static let inputDirection = "inputDirection"
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suite)
    }

    static var slangEnabled: Bool {
        get {
            // 디폴트 ON — 처음 켤 때 슬랭이 보여서 기능 발견 ↑
            defaults?.object(forKey: Keys.slangEnabled) as? Bool ?? true
        }
        set {
            defaults?.set(newValue, forKey: Keys.slangEnabled)
        }
    }

    static var inputDirection: InputDirection {
        get {
            guard let raw = defaults?.string(forKey: Keys.inputDirection),
                  let dir = InputDirection(rawValue: raw)
            else { return .kor2ind }
            return dir
        }
        set {
            defaults?.set(newValue.rawValue, forKey: Keys.inputDirection)
        }
    }
}
