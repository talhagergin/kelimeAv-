import Foundation

struct GameResult: Identifiable, Codable {
    let id: UUID
    let mode: GameMode.RawValue
    let score: Int
    let correctCount: Int
    let wrongCount: Int
    let revealedLetterCount: Int
    let stars: Int
    let completedAt: Date

    init(
        id: UUID = UUID(),
        mode: GameMode,
        score: Int,
        correctCount: Int,
        wrongCount: Int,
        revealedLetterCount: Int,
        stars: Int = 0,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.mode = mode.rawValue
        self.score = score
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.revealedLetterCount = revealedLetterCount
        self.stars = stars
        self.completedAt = completedAt
    }
}
