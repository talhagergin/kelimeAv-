import Foundation

protocol PrivateChallengeProviding {
    func createChallenge(creatorName: String, questionCount: Int, totalTime: Int, maxDifficulty: Int) -> PrivateChallenge
    func shareCode(for challenge: PrivateChallenge) -> String
    func shareURL(for challenge: PrivateChallenge) -> URL
    func challenge(from text: String) -> PrivateChallenge?
}

final class PrivateChallengeService: PrivateChallengeProviding {
    private let questionService: QuestionProviding

    init(questionService: QuestionProviding? = nil) {
        self.questionService = questionService ?? QuestionService()
    }

    func createChallenge(
        creatorName: String,
        questionCount: Int,
        totalTime: Int,
        maxDifficulty: Int
    ) -> PrivateChallenge {
        let questions = questionService.privateChallengeQuestions(
            count: questionCount,
            maxDifficulty: maxDifficulty
        )
        let cleanName = creatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = cleanName.isEmpty ? "Oyuncu" : cleanName

        return PrivateChallenge(
            creatorName: displayName,
            title: "\(displayName) meydan okuyor",
            questionIDs: questions.map(\.id),
            totalTime: min(max(totalTime, 90), 300),
            maxDifficulty: min(max(maxDifficulty, 1), 5)
        )
    }

    func shareCode(for challenge: PrivateChallenge) -> String {
        guard let data = try? JSONEncoder().encode(challenge) else { return "" }
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func shareURL(for challenge: PrivateChallenge) -> URL {
        let code = shareCode(for: challenge)
        return URL(string: "kelimeavi://private-challenge?code=\(code)")!
    }

    func challenge(from text: String) -> PrivateChallenge? {
        let rawCode = extractCode(from: text)
        var normalized = rawCode
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = normalized.count % 4
        if remainder > 0 {
            normalized.append(String(repeating: "=", count: 4 - remainder))
        }

        guard let data = Data(base64Encoded: normalized) else { return nil }
        return try? JSONDecoder().decode(PrivateChallenge.self, from: data)
    }

    private func extractCode(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return trimmed
        }
        return code
    }
}
