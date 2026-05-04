import Foundation

struct PrivateChallenge: Identifiable, Codable, Hashable {
    let id: UUID
    let creatorName: String
    let title: String
    let questionIDs: [UUID]
    let totalTime: Int
    let maxDifficulty: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        creatorName: String,
        title: String,
        questionIDs: [UUID],
        totalTime: Int,
        maxDifficulty: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.creatorName = creatorName
        self.title = title
        self.questionIDs = questionIDs
        self.totalTime = totalTime
        self.maxDifficulty = maxDifficulty
        self.createdAt = createdAt
    }
}
