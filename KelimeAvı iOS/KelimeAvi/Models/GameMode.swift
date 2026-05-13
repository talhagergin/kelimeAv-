import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case challenge
    case categoryChallenge
    case privateChallenge
    case daily
    case quickTour

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Klasik Mod"
        case .challenge: "Challenge Mod"
        case .categoryChallenge: "Kategori Haritası"
        case .privateChallenge: "Private Challenge"
        case .daily: "Günlük Kelime Avı"
        case .quickTour: "Hızlı Tur"
        }
    }
}
