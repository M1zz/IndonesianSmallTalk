import Foundation

enum Polarity: String, Codable, CaseIterable {
    case positive, negative, neutral

    var label: String {
        switch self {
        case .positive: return "Positif +"
        case .negative: return "Negatif −"
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
