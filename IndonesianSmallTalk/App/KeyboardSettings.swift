import Foundation

/// App Group UserDefaults 로 메인 앱과 키보드 익스텐션이 공유하는 설정.
/// 키보드가 어느 방향으로 입력하는지.
/// - kor2ind: 사용자가 한국어를 보고 탭 → 인도네시아어 입력 (한→인)
/// - ind2kor: 사용자가 인도네시아어를 보고 탭 → 한국어 입력 (인→한)
enum InputDirection: String, Codable {
    case kor2ind
    case ind2kor

    var symbol: String {
        switch self {
        case .kor2ind: return "한 → 인"
        case .ind2kor: return "인 → 한"
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
