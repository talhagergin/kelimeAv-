import Foundation

protocol QuestionProviding {
    func classicQuestions() -> [WordQuestion]
    func challengeQuestions(level: Int) -> [WordQuestion]
}

final class QuestionService: QuestionProviding {
    private let questions: [WordQuestion]

    init(bundle: Bundle = .main) {
        self.questions = Self.loadQuestions(bundle: bundle)
    }

    func classicQuestions() -> [WordQuestion] {
        let orderedPool = questions
            .filter { $0.letterCount >= 3 }
            .sorted { lhs, rhs in
                if lhs.letterCount == rhs.letterCount {
                    return lhs.difficulty < rhs.difficulty
                }
                return lhs.letterCount < rhs.letterCount
            }

        let buckets = Dictionary(grouping: orderedPool.shuffled()) { $0.letterCount }
        let targetLengths = [3, 4, 5, 6, 7, 8, 9]
        var used = Set<UUID>()

        let selected = targetLengths.flatMap { length -> [WordQuestion] in
            let picks = buckets[length]?
                .filter { !used.contains($0.id) }
                .shuffled()
                .prefix(2) ?? []

            picks.forEach { used.insert($0.id) }
            return Array(picks).shuffled()
        }

        if selected.count >= 14 {
            return selected
        }

        let extras = orderedPool
            .filter { !used.contains($0.id) }
            .shuffled()
            .prefix(14 - selected.count)

        return selected + extras
    }

    func challengeQuestions(level: Int) -> [WordQuestion] {
        let targetDifficulty = min(max(level, 1), 5)
        let pool = questions
            .filter { $0.difficulty <= targetDifficulty + 1 }
            .shuffled()

        return Array(pool.prefix(min(5 + level, 8)))
    }

    private static func loadQuestions(bundle: Bundle) -> [WordQuestion] {
        guard let url = bundle.url(forResource: "questions", withExtension: "json") else {
            return fallbackQuestions
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([WordQuestion].self, from: data)
        } catch {
            return fallbackQuestions
        }
    }

    private static let fallbackQuestions: [WordQuestion] = [
        WordQuestion(
            clue: "Uçmak için kullanılan taşıt",
            extendedClue: "Havada yolculuk yapmak için kullanılan motorlu taşıt",
            answer: "UÇAK",
            difficulty: 1,
            category: "Genel Kültür",
            letterCount: 4
        )
    ]
}
