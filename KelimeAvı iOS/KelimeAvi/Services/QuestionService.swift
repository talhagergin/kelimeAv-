import Foundation

protocol QuestionProviding {
    func classicQuestions(maxDifficulty: Int) -> [WordQuestion]
    func challengeQuestions(level: Int) -> [WordQuestion]
    func categoryQuestions(category: String, level: Int) -> [WordQuestion]
    func categoryQuestions(category: String, level: Int, count: Int) -> [WordQuestion]
    func quickTourQuestions() -> [WordQuestion]
    func privateChallengeQuestions(count: Int, maxDifficulty: Int) -> [WordQuestion]
    func privateChallengeQuestions(count: Int, maxDifficulty: Int, seed: UInt64) -> [WordQuestion]
    func privateChallengeQuestions(count: Int, maxDifficulty: Int, seed: UInt64, category: String?) -> [WordQuestion]
    func dailyQuestions(for date: Date) -> [WordQuestion]
    func questions(matching ids: [UUID]) -> [WordQuestion]
    func categoryCounts() -> [(category: String, count: Int)]
}

final class QuestionService: QuestionProviding {
    private let questions: [WordQuestion]

    init(bundle: Bundle = .main) {
        self.questions = Self.loadQuestions(bundle: bundle)
    }

    func classicQuestions(maxDifficulty: Int = 3) -> [WordQuestion] {
        let difficulty = min(max(maxDifficulty, 2), 5)
        let orderedPool = uniqueQuestions(from: questions)
            .filter { $0.letterCount >= 3 && $0.difficulty <= difficulty }
            .sorted { lhs, rhs in
                if lhs.letterCount == rhs.letterCount {
                    return lhs.difficulty < rhs.difficulty
                }
                return lhs.letterCount < rhs.letterCount
            }

        let buckets = Dictionary(grouping: orderedPool.shuffled()) { $0.letterCount }
        let plan: [(length: Int, maxDifficulty: Int)] = [
            (3, difficulty), (3, difficulty),
            (4, difficulty), (4, difficulty),
            (5, difficulty), (5, difficulty),
            (6, difficulty), (6, difficulty),
            (7, difficulty), (7, difficulty),
            (8, difficulty), (8, difficulty),
            (9, difficulty), (9, difficulty),
            (10, difficulty), (10, difficulty)
        ]
        var used = Set<UUID>()
        var usedAnswers = Set<String>()
        var lastCategory: String?

        var selected: [WordQuestion] = []

        for slot in plan {
            guard let question = pickQuestion(
                from: buckets,
                length: slot.length,
                maxDifficulty: slot.maxDifficulty,
                used: used,
                usedAnswers: usedAnswers,
                avoidingCategory: lastCategory
            ) else {
                continue
            }
            selected.append(question)
            used.insert(question.id)
            usedAnswers.insert(question.answer.turkishGameNormalized())
            lastCategory = question.category
        }

        if selected.count >= 16 {
            return selected
        }

        let extras = orderedPool
            .filter {
                !used.contains($0.id) &&
                !usedAnswers.contains($0.answer.turkishGameNormalized())
            }
            .shuffled()
            .prefix(16 - selected.count)

        return selected + extras
    }

    func challengeQuestions(level: Int) -> [WordQuestion] {
        let targetDifficulty = min(max(level, 1), 5)
        let pool = uniqueQuestions(from: questions)
            .filter { $0.difficulty <= targetDifficulty + 1 }
            .shuffled()

        return Array(pool.prefix(min(5 + level, 8)))
    }

    func categoryQuestions(category: String, level: Int) -> [WordQuestion] {
        categoryQuestions(category: category, level: level, count: min(5 + level, 8))
    }

    func categoryQuestions(category: String, level: Int, count: Int) -> [WordQuestion] {
        let targetDifficulty = min(max(level, 1), 5)
        let safeCount = min(max(count, 1), 15)
        let normalizedCategory = category.turkishGameNormalized()
        let categoryPool = uniqueQuestions(from: questions)
            .filter { $0.category.turkishGameNormalized() == normalizedCategory }

        let preferred = categoryPool
            .filter { $0.difficulty <= targetDifficulty + 1 }
            .shuffled()
        let fallback = categoryPool
            .filter { !preferred.map(\.id).contains($0.id) }
            .shuffled()

        return Array((preferred + fallback).prefix(safeCount))
    }

    func dailyQuestions(for date: Date = Date()) -> [WordQuestion] {
        let day = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        let seed = UInt64(day) ^ 0xA11CE5EED
        let pool = uniqueQuestions(from: questions)
            .filter { $0.letterCount >= 4 && $0.letterCount <= 8 && $0.difficulty <= 4 }
            .seededShuffled(seed: seed)
        return Array(pool.prefix(5))
    }

    func quickTourQuestions() -> [WordQuestion] {
        let pool = uniqueQuestions(from: questions)
            .filter { $0.letterCount >= 3 && $0.letterCount <= 8 && $0.difficulty <= 4 }
            .shuffled()

        return Array(pool.prefix(60))
    }

    func privateChallengeQuestions(count: Int, maxDifficulty: Int) -> [WordQuestion] {
        privateChallengeQuestions(count: count, maxDifficulty: maxDifficulty, seed: UInt64.random(in: 1...UInt64.max))
    }

    func privateChallengeQuestions(count: Int, maxDifficulty: Int, seed: UInt64) -> [WordQuestion] {
        privateChallengeQuestions(count: count, maxDifficulty: maxDifficulty, seed: seed, category: nil)
    }

    func privateChallengeQuestions(count: Int, maxDifficulty: Int, seed: UInt64, category: String?) -> [WordQuestion] {
        let safeCount = min(max(count, 6), 16)
        let difficulty = min(max(maxDifficulty, 2), 5)
        let normalizedCategory = category?.turkishGameNormalized()
        let basePool = uniqueQuestions(from: questions)
            .filter { $0.letterCount >= 3 && $0.difficulty <= difficulty }
        let categoryPool = normalizedCategory.map { normalized in
            basePool.filter { $0.category.turkishGameNormalized() == normalized }
        } ?? basePool
        let orderedPool = categoryPool
            .seededShuffled(seed: seed)

        let buckets = Dictionary(grouping: orderedPool) { $0.letterCount }
        let lengths = [3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
            .prefix(safeCount)
        var selected: [WordQuestion] = []
        var usedAnswers = Set<String>()
        var random = SeededRandomNumberGenerator(seed: seed)

        for length in lengths {
            guard let question = buckets[length]?
                .filter({ !usedAnswers.contains($0.answer.turkishGameNormalized()) })
                .randomElement(using: &random) else {
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

    func categoryCounts() -> [(category: String, count: Int)] {
        Dictionary(grouping: uniqueQuestions(from: questions), by: \.category)
            .map { (category: $0.key, count: $0.value.count) }
            .filter { $0.count >= 5 }
            .sorted {
                let lhsRank = stableCategoryRank($0.category)
                let rhsRank = stableCategoryRank($1.category)
                if lhsRank == rhsRank {
                    return $0.category.localizedStandardCompare($1.category) == .orderedAscending
                }
                return lhsRank < rhsRank
            }
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

    private func pickQuestion(
        from buckets: [Int: [WordQuestion]],
        length: Int,
        maxDifficulty: Int,
        used: Set<UUID>,
        usedAnswers: Set<String>,
        avoidingCategory: String? = nil
    ) -> WordQuestion? {
        guard let bucket = buckets[length] else { return nil }

        for difficultyCap in maxDifficulty...5 {
            let candidates = bucket.filter {
                $0.difficulty <= difficultyCap &&
                !used.contains($0.id) &&
                !usedAnswers.contains($0.answer.turkishGameNormalized()) &&
                $0.category != avoidingCategory
            }
            if let question = candidates.randomElement() {
                return question
            }
        }

        return bucket.filter {
            !used.contains($0.id) &&
            !usedAnswers.contains($0.answer.turkishGameNormalized())
        }
        .randomElement()
    }

    private func stableCategoryRank(_ category: String) -> Int {
        var value = 0x4B41
        for scalar in category.unicodeScalars {
            value = ((value &* 31) &+ Int(scalar.value)) % 9973
        }
        return value
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

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

private extension Array {
    func seededShuffled(seed: UInt64) -> [Element] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return shuffled(using: &generator)
    }
}
