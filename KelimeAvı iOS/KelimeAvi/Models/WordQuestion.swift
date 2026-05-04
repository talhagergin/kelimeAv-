import Foundation

struct WordQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let clue: String
    let extendedClue: String
    let answer: String
    let difficulty: Int
    let category: String
    let letterCount: Int

    init(
        id: UUID = UUID(),
        clue: String,
        extendedClue: String,
        answer: String,
        difficulty: Int,
        category: String,
        letterCount: Int
    ) {
        self.id = id
        self.clue = clue
        self.extendedClue = extendedClue
        self.answer = answer.turkishGameNormalized()
        self.difficulty = difficulty
        self.category = category
        self.letterCount = letterCount
    }
}

extension String {
    func turkishGameNormalized() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(with: Locale(identifier: "tr_TR"))
    }

    var turkishLetters: [String] {
        map(String.init)
    }
}
