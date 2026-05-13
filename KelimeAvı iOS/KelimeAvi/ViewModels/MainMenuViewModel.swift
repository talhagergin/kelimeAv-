import Combine
import Foundation

@MainActor
final class MainMenuViewModel: ObservableObject {
    @Published var classicHighScore: Int = 0
    @Published var coins: Int = 0
    @Published var dailyStreak: Int = 0
    @Published var isDailyCompletedToday = false

    private let scoreService: ScoreStoring

    init(scoreService: ScoreStoring? = nil) {
        self.scoreService = scoreService ?? ScoreService()
        refresh()
    }

    func refresh() {
        classicHighScore = scoreService.classicHighScore
        coins = scoreService.coins
        dailyStreak = scoreService.dailyStreak()
        isDailyCompletedToday = scoreService.isDailyCompletedToday(date: Date())
    }
}
