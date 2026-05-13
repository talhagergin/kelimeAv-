import Foundation

enum BadgeType: String, CaseIterable, Identifiable, Codable {
    case noHintRun
    case categoryExpert
    case dailyStreak
    case comboMaster

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noHintRun: "Temiz Seri"
        case .categoryExpert: "Kategori Uzmanı"
        case .dailyStreak: "Günlük Avcı"
        case .comboMaster: "Kombo Ustası"
        }
    }

    var description: String {
        switch self {
        case .noHintRun: "Bir oyunda harf almadan 5 doğru yap."
        case .categoryExpert: "Kategori modunda 4 doğru cevap ver."
        case .dailyStreak: "Günlük Kelime Avı serisini 10 güne çıkar."
        case .comboMaster: "Klasik dışı modlarda 3 kombo yakala."
        }
    }

    var rewardCoins: Int {
        switch self {
        case .categoryExpert: 8
        case .comboMaster: 10
        case .noHintRun: 14
        case .dailyStreak: 30
        }
    }

    var iconName: String {
        switch self {
        case .noHintRun: "sparkle.magnifyingglass"
        case .categoryExpert: "tag.fill"
        case .dailyStreak: "flame.fill"
        case .comboMaster: "bolt.circle.fill"
        }
    }
}
