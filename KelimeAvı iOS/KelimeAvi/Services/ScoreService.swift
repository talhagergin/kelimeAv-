import Foundation

protocol ScoreStoring {
    var classicHighScore: Int { get }
    var coins: Int { get }
    var fastestCorrectSeconds: Int { get }
    var selectedTileSkin: TileSkin { get }
    func saveClassicScore(_ score: Int)
    func saveFastestCorrect(seconds: Int) -> Bool
    func stars(forLevel level: Int) -> Int
    func saveStars(_ stars: Int, forLevel level: Int)
    func categoryMapUnlockedCount() -> Int
    func requiredStarsForCategoryMapNode(at index: Int) -> Int
    func completeCategoryMapNode(at index: Int, stars: Int)
    func addCoins(_ amount: Int)
    func spendCoins(_ amount: Int) -> Bool
    func inventoryCount(for joker: JokerType) -> Int
    func addInventory(_ amount: Int, for joker: JokerType)
    func spendInventory(for joker: JokerType) -> Bool
    func isBadgeUnlocked(_ badge: BadgeType) -> Bool
    func unlockBadge(_ badge: BadgeType) -> Bool
    func dailyStreak() -> Int
    func isDailyCompletedToday(date: Date) -> Bool
    func markDailyStarted(date: Date)
    func abandonDaily(date: Date)
    func updateDailyStreakIfNeeded(for date: Date) -> Int
    func isTileSkinUnlocked(_ skin: TileSkin) -> Bool
    func unlockTileSkin(_ skin: TileSkin) -> Bool
    func selectTileSkin(_ skin: TileSkin)
    func privateRoomsCreatedToday(date: Date) -> Int
    func markPrivateRoomCreated(date: Date)
}

enum TileSkin: String, CaseIterable, Identifiable, Codable {
    case classicBlue
    case royalPurple
    case sunset
    case mint
    case ruby
    case emerald
    case ocean
    case lemon
    case graphite
    case candy
    case galaxy
    case neon
    case ice
    case rose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicBlue: "Klasik Mavi"
        case .royalPurple: "Kraliyet Moru"
        case .sunset: "Gün Batımı"
        case .mint: "Nane Işığı"
        case .ruby: "Yakut"
        case .emerald: "Zümrüt"
        case .ocean: "Okyanus"
        case .lemon: "Limon"
        case .graphite: "Grafit"
        case .candy: "Şeker Deseni"
        case .galaxy: "Galaksi"
        case .neon: "Neon"
        case .ice: "Buz"
        case .rose: "Gül"
        }
    }

    var price: Int {
        switch self {
        case .classicBlue: 0
        case .royalPurple: 22
        case .sunset: 28
        case .mint: 34
        case .ruby: 24
        case .emerald: 26
        case .ocean: 26
        case .lemon: 18
        case .graphite: 20
        case .candy: 36
        case .galaxy: 42
        case .neon: 46
        case .ice: 30
        case .rose: 28
        }
    }
}

final class ScoreService: ScoreStoring {
    private let defaults: UserDefaults
    private let classicHighScoreKey = "classicHighScore"
    private let coinsKey = "playerCoins"
    private let challengeStarsPrefix = "challengeStars.level."
    private let categoryMapUnlockedCountKey = "categoryMapUnlockedCount"
    private let jokerInventoryPrefix = "jokerInventory."
    private let didSeedDefaultInventoryKey = "didSeedDefaultInventory.v2"
    private let badgePrefix = "badge."
    private let fastestCorrectKey = "fastestCorrectSeconds"
    private let selectedTileSkinKey = "selectedTileSkin"
    private let tileSkinPrefix = "tileSkin."
    private let dailyStreakKey = "dailyStreak"
    private let lastDailyCompletionKey = "lastDailyCompletion"
    private let lastDailyAttemptKey = "lastDailyAttempt"
    private let privateRoomCreationDateKey = "privateRoomCreationDate"
    private let privateRoomCreationCountKey = "privateRoomCreationCount"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        seedDefaultInventoryIfNeeded()
    }

    var classicHighScore: Int {
        defaults.integer(forKey: classicHighScoreKey)
    }

    var coins: Int {
        defaults.integer(forKey: coinsKey)
    }

    var fastestCorrectSeconds: Int {
        defaults.integer(forKey: fastestCorrectKey)
    }

    var selectedTileSkin: TileSkin {
        guard let rawValue = defaults.string(forKey: selectedTileSkinKey),
              let skin = TileSkin(rawValue: rawValue),
              isTileSkinUnlocked(skin) else {
            return .classicBlue
        }
        return skin
    }

    func saveClassicScore(_ score: Int) {
        guard score > classicHighScore else { return }
        defaults.set(score, forKey: classicHighScoreKey)
    }

    func saveFastestCorrect(seconds: Int) -> Bool {
        guard seconds > 0 else { return false }
        let current = fastestCorrectSeconds
        guard current == 0 || seconds < current else { return false }
        defaults.set(seconds, forKey: fastestCorrectKey)
        return true
    }

    func stars(forLevel level: Int) -> Int {
        defaults.integer(forKey: challengeStarsPrefix + "\(level)")
    }

    func saveStars(_ stars: Int, forLevel level: Int) {
        let key = challengeStarsPrefix + "\(level)"
        guard stars > defaults.integer(forKey: key) else { return }
        defaults.set(stars, forKey: key)
    }

    func categoryMapUnlockedCount() -> Int {
        max(defaults.integer(forKey: categoryMapUnlockedCountKey), 1)
    }

    func requiredStarsForCategoryMapNode(at index: Int) -> Int {
        if index >= 15 { return 3 }
        if index >= 9 { return 2 }
        return 1
    }

    func completeCategoryMapNode(at index: Int, stars: Int) {
        let current = categoryMapUnlockedCount()
        guard index < current, stars >= requiredStarsForCategoryMapNode(at: index) else { return }
        defaults.set(max(current, index + 2), forKey: categoryMapUnlockedCountKey)
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

    func inventoryCount(for joker: JokerType) -> Int {
        defaults.integer(forKey: jokerInventoryPrefix + joker.rawValue)
    }

    func addInventory(_ amount: Int, for joker: JokerType) {
        guard amount > 0 else { return }
        let key = jokerInventoryPrefix + joker.rawValue
        defaults.set(defaults.integer(forKey: key) + amount, forKey: key)
    }

    func spendInventory(for joker: JokerType) -> Bool {
        let key = jokerInventoryPrefix + joker.rawValue
        let current = defaults.integer(forKey: key)
        guard current > 0 else { return false }
        defaults.set(current - 1, forKey: key)
        return true
    }

    func isBadgeUnlocked(_ badge: BadgeType) -> Bool {
        defaults.bool(forKey: badgePrefix + badge.rawValue)
    }

    func unlockBadge(_ badge: BadgeType) -> Bool {
        let key = badgePrefix + badge.rawValue
        guard !defaults.bool(forKey: key) else { return false }
        defaults.set(true, forKey: key)
        return true
    }

    func dailyStreak() -> Int {
        defaults.integer(forKey: dailyStreakKey)
    }

    func isDailyCompletedToday(date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        if let last = defaults.object(forKey: lastDailyCompletionKey) as? Date,
           calendar.isDate(last, inSameDayAs: date) {
            return true
        }

        if let lastAttempt = defaults.object(forKey: lastDailyAttemptKey) as? Date,
           calendar.isDate(lastAttempt, inSameDayAs: date) {
            return true
        }

        return false
    }

    func markDailyStarted(date: Date = Date()) {
        defaults.set(Calendar.current.startOfDay(for: date), forKey: lastDailyAttemptKey)
    }

    func abandonDaily(date: Date = Date()) {
        let today = Calendar.current.startOfDay(for: date)
        defaults.set(today, forKey: lastDailyAttemptKey)
        defaults.set(0, forKey: dailyStreakKey)
    }

    func updateDailyStreakIfNeeded(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let last = defaults.object(forKey: lastDailyCompletionKey) as? Date

        if let last, calendar.isDate(last, inSameDayAs: today) {
            return dailyStreak()
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let nextStreak: Int
        if let last, let yesterday, calendar.isDate(last, inSameDayAs: yesterday) {
            nextStreak = dailyStreak() + 1
        } else {
            nextStreak = 1
        }

        defaults.set(today, forKey: lastDailyCompletionKey)
        defaults.set(nextStreak, forKey: dailyStreakKey)
        return nextStreak
    }

    func isTileSkinUnlocked(_ skin: TileSkin) -> Bool {
        skin == .classicBlue || defaults.bool(forKey: tileSkinPrefix + skin.rawValue)
    }

    func unlockTileSkin(_ skin: TileSkin) -> Bool {
        guard !isTileSkinUnlocked(skin), skin.price > 0, spendCoins(skin.price) else { return false }
        defaults.set(true, forKey: tileSkinPrefix + skin.rawValue)
        return true
    }

    func selectTileSkin(_ skin: TileSkin) {
        guard isTileSkinUnlocked(skin) else { return }
        defaults.set(skin.rawValue, forKey: selectedTileSkinKey)
    }

    func privateRoomsCreatedToday(date: Date = Date()) -> Int {
        let today = Calendar.current.startOfDay(for: date)
        guard let savedDate = defaults.object(forKey: privateRoomCreationDateKey) as? Date,
              Calendar.current.isDate(savedDate, inSameDayAs: today) else {
            return 0
        }
        return defaults.integer(forKey: privateRoomCreationCountKey)
    }

    func markPrivateRoomCreated(date: Date = Date()) {
        let today = Calendar.current.startOfDay(for: date)
        let current = privateRoomsCreatedToday(date: date)
        defaults.set(today, forKey: privateRoomCreationDateKey)
        defaults.set(current + 1, forKey: privateRoomCreationCountKey)
    }

    private func seedDefaultInventoryIfNeeded() {
        guard !defaults.bool(forKey: didSeedDefaultInventoryKey) else { return }
        let initialInventory: [JokerType: Int] = [
            .firstLetter: 1,
            .removeWrongLetters: 1,
            .freezeTime: 1,
            .extendClue: 3
        ]

        for (joker, amount) in initialInventory {
            let key = jokerInventoryPrefix + joker.rawValue
            defaults.set(defaults.integer(forKey: key) + amount, forKey: key)
        }

        defaults.set(true, forKey: tileSkinPrefix + TileSkin.classicBlue.rawValue)
        defaults.set(TileSkin.classicBlue.rawValue, forKey: selectedTileSkinKey)
        defaults.set(true, forKey: didSeedDefaultInventoryKey)
    }
}
