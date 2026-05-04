import Foundation

protocol ScoreStoring {
    var classicHighScore: Int { get }
    var coins: Int { get }
    func saveClassicScore(_ score: Int)
    func stars(forLevel level: Int) -> Int
    func saveStars(_ stars: Int, forLevel level: Int)
    func addCoins(_ amount: Int)
    func spendCoins(_ amount: Int) -> Bool
}

final class ScoreService: ScoreStoring {
    private let defaults: UserDefaults
    private let classicHighScoreKey = "classicHighScore"
    private let coinsKey = "playerCoins"
    private let challengeStarsPrefix = "challengeStars.level."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var classicHighScore: Int {
        defaults.integer(forKey: classicHighScoreKey)
    }

    var coins: Int {
        defaults.integer(forKey: coinsKey)
    }

    func saveClassicScore(_ score: Int) {
        guard score > classicHighScore else { return }
        defaults.set(score, forKey: classicHighScoreKey)
    }

    func stars(forLevel level: Int) -> Int {
        defaults.integer(forKey: challengeStarsPrefix + "\(level)")
    }

    func saveStars(_ stars: Int, forLevel level: Int) {
        let key = challengeStarsPrefix + "\(level)"
        guard stars > defaults.integer(forKey: key) else { return }
        defaults.set(stars, forKey: key)
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        defaults.set(coins + amount, forKey: coinsKey)
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        defaults.set(coins - amount, forKey: coinsKey)
        return true
    }
}
