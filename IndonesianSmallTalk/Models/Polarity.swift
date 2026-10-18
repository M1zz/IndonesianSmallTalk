import Foundation

enum Polarity: String, Codable, CaseIterable {
    case positive, negative, neutral

    var label: String {
        switch self {
        case .positive: return String(localized: "긍정 +")
        case .negative: return String(localized: "부정 −")
        case .neutral:  return ""
        }
    }

    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😟"
        case .neutral:  return "💬"
        }
    }
}
