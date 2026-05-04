import Combine
import Foundation

@MainActor
final class ChallengeViewModel: ObservableObject {
    @Published var selectedLevel: Int = 1

    private let scoreService: ScoreStoring

    init(scoreService: ScoreStoring? = nil) {
        self.scoreService = scoreService ?? ScoreService()
    }

    func stars(for level: Int) -> Int {
        scoreService.stars(forLevel: level)
    }
}
