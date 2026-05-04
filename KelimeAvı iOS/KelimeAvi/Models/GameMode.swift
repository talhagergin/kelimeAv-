import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case challenge
    case privateChallenge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Klasik Mod"
        case .challenge: "Challenge Mod"
        case .privateChallenge: "Private Challenge"
        }
    }
}
