import Foundation

enum JokerType: String, CaseIterable, Identifiable, Codable {
    case revealLetter
    case firstLetter
    case removeWrongLetters
    case freezeTime
    case extendClue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .revealLetter: "Harf Aç"
        case .firstLetter: "İlk Harf"
        case .removeWrongLetters: "Yanlışları Sil"
        case .freezeTime: "Süre Dondur"
        case .extendClue: "İpucu Genişlet"
        }
    }

    var iconName: String {
        switch self {
        case .revealLetter: "sparkles"
        case .firstLetter: "1.circle.fill"
        case .removeWrongLetters: "eraser.fill"
        case .freezeTime: "snowflake"
        case .extendClue: "lightbulb.fill"
        }
    }
}
