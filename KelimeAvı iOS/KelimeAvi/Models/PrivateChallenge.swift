import Foundation

struct PrivateChallenge: Identifiable, Codable, Hashable {
    let id: UUID
    let creatorName: String
    let title: String
    let questionIDs: [UUID]
    let totalTime: Int
    let maxDifficulty: Int
    let passLimit: Int
    let category: String?
    let createdAt: Date
    let seed: UInt64

    init(
        id: UUID = UUID(),
        creatorName: String,
        title: String,
        questionIDs: [UUID],
        totalTime: Int,
        maxDifficulty: Int,
        passLimit: Int = 0,
        category: String? = nil,
        createdAt: Date = Date(),
        seed: UInt64 = UInt64.random(in: 1...UInt64.max)
    ) {
        self.id = id
        self.creatorName = creatorName
        self.title = title
        self.questionIDs = questionIDs
        self.totalTime = totalTime
        self.maxDifficulty = maxDifficulty
        self.passLimit = passLimit
        self.category = category
        self.createdAt = createdAt
        self.seed = seed
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case creatorName
        case title
        case questionIDs
        case totalTime
        case maxDifficulty
        case passLimit
        case category
        case createdAt
        case seed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        creatorName = try container.decode(String.self, forKey: .creatorName)
        title = try container.decode(String.self, forKey: .title)
        questionIDs = try container.decode([UUID].self, forKey: .questionIDs)
        totalTime = try container.decode(Int.self, forKey: .totalTime)
        maxDifficulty = try container.decode(Int.self, forKey: .maxDifficulty)
        passLimit = try container.decodeIfPresent(Int.self, forKey: .passLimit) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        seed = try container.decodeIfPresent(UInt64.self, forKey: .seed) ?? UInt64(id.uuidString.hashValue.magnitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(creatorName, forKey: .creatorName)
        try container.encode(title, forKey: .title)
        try container.encode(questionIDs, forKey: .questionIDs)
        try container.encode(totalTime, forKey: .totalTime)
        try container.encode(maxDifficulty, forKey: .maxDifficulty)
        try container.encode(passLimit, forKey: .passLimit)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(seed, forKey: .seed)
    }
}
