import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case challenge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Klasik Mod"
        case .challenge: "Challenge Mod"
        }
    }
}
