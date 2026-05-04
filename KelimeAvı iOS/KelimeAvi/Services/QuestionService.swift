import Foundation

protocol QuestionProviding {
    func classicQuestions() -> [WordQuestion]
    func challengeQuestions(level: Int) -> [WordQuestion]
    func privateChallengeQuestions(count: Int, maxDifficulty: Int) -> [WordQuestion]
    func questions(matching ids: [UUID]) -> [WordQuestion]
}

final class QuestionService: QuestionProviding {
    private let questions: [WordQuestion]

    init(bundle: Bundle = .main) {
        self.questions = Self.loadQuestions(bundle: bundle)
    }

    func classicQuestions() -> [WordQuestion] {
        let orderedPool = uniqueQuestions(from: questions)
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
        var usedAnswers = Set<String>()

        let selected = targetLengths.flatMap { length -> [WordQuestion] in
            let picks = buckets[length]?
                .filter {
                    !used.contains($0.id) &&
                    !usedAnswers.contains($0.answer.turkishGameNormalized())
                }
                .shuffled()
                .prefix(2) ?? []

            picks.forEach { used.insert($0.id) }
            picks.forEach { usedAnswers.insert($0.answer.turkishGameNormalized()) }
            return Array(picks).shuffled()
        }

        if selected.count >= 14 {
            return selected
        }

        let extras = orderedPool
            .filter {
                !used.contains($0.id) &&
                !usedAnswers.contains($0.answer.turkishGameNormalized())
            }
            .shuffled()
            .prefix(14 - selected.count)

        return selected + extras
    }

    func challengeQuestions(level: Int) -> [WordQuestion] {
        let targetDifficulty = min(max(level, 1), 5)
        let pool = uniqueQuestions(from: questions)
            .filter { $0.difficulty <= targetDifficulty + 1 }
            .shuffled()

        return Array(pool.prefix(min(5 + level, 8)))
    }

    func privateChallengeQuestions(count: Int, maxDifficulty: Int) -> [WordQuestion] {
        let safeCount = min(max(count, 6), 14)
        let difficulty = min(max(maxDifficulty, 1), 5)
        let orderedPool = uniqueQuestions(from: questions)
            .filter { $0.letterCount >= 3 && $0.difficulty <= difficulty }
            .shuffled()

        let buckets = Dictionary(grouping: orderedPool) { $0.letterCount }
        let lengths = [3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]
            .prefix(safeCount)
        var selected: [WordQuestion] = []
        var usedAnswers = Set<String>()

        for length in lengths {
            guard let question = buckets[length]?
                .filter({ !usedAnswers.contains($0.answer.turkishGameNormalized()) })
                .randomElement() else {
                continue
            }
            selected.append(question)
            usedAnswers.insert(question.answer.turkishGameNormalized())
        }

        if selected.count < safeCount {
            let extras = orderedPool
                .filter { !usedAnswers.contains($0.answer.turkishGameNormalized()) }
                .prefix(safeCount - selected.count)
            selected.append(contentsOf: extras)
        }

        return selected
    }

    func questions(matching ids: [UUID]) -> [WordQuestion] {
        let lookup = questions.reduce(into: [UUID: WordQuestion]()) { partialResult, question in
            partialResult[question.id] = question
        }
        return ids.compactMap { lookup[$0] }
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

    private func uniqueQuestions(from source: [WordQuestion]) -> [WordQuestion] {
        var seen = Set<String>()
        return source.filter { question in
            let key = "\(question.answer.turkishGameNormalized())|\(question.clue.turkishGameNormalized())"
            return seen.insert(key).inserted
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
