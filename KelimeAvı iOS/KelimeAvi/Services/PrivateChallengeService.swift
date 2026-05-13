import Foundation

protocol PrivateChallengeProviding {
    func createChallenge(creatorName: String, questionCount: Int, totalTime: Int, maxDifficulty: Int, passLimit: Int, category: String?) -> PrivateChallenge
    func shareCode(for challenge: PrivateChallenge) -> String
    func shareURL(for challenge: PrivateChallenge) -> URL
    func challenge(from text: String) -> PrivateChallenge?
    func hasJoined(_ challenge: PrivateChallenge) -> Bool
    func markJoined(_ challenge: PrivateChallenge)
}

final class PrivateChallengeService: PrivateChallengeProviding {
    private let questionService: QuestionProviding
    private let defaults: UserDefaults
    private let joinedKey = "joinedPrivateChallengeIDs"

    init(questionService: QuestionProviding? = nil, defaults: UserDefaults = .standard) {
        self.questionService = questionService ?? QuestionService()
        self.defaults = defaults
    }

    func createChallenge(
        creatorName: String,
        questionCount: Int,
        totalTime: Int,
        maxDifficulty: Int,
        passLimit: Int = 0,
        category: String? = nil
    ) -> PrivateChallenge {
        let seed = UInt64.random(in: 1...UInt64.max)
        let safeCount = min(max(questionCount, 6), 16)
        let safeTime = min(max(totalTime, 90), 300)
        let safeDifficulty = min(max(maxDifficulty, 2), 5)
        let safePassLimit = min(max(passLimit, 0), 5)
        let cleanCategory = sanitizedCategory(category)
        let questions = questionService.privateChallengeQuestions(
            count: safeCount,
            maxDifficulty: safeDifficulty,
            seed: seed,
            category: cleanCategory
        )
        let cleanName = creatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = cleanName.isEmpty ? "Oyuncu" : cleanName

        return PrivateChallenge(
            id: deterministicID(seed: seed, questionCount: questions.count, totalTime: safeTime, maxDifficulty: safeDifficulty, passLimit: safePassLimit, category: cleanCategory),
            creatorName: displayName,
            title: cleanCategory.map { "\(displayName) \($0) kategorisinde meydan okuyor" } ?? "\(displayName) meydan okuyor",
            questionIDs: questions.map(\.id),
            totalTime: safeTime,
            maxDifficulty: safeDifficulty,
            passLimit: safePassLimit,
            category: cleanCategory,
            seed: seed
        )
    }

    func shareCode(for challenge: PrivateChallenge) -> String {
        let encodedName = encodeText(challenge.creatorName) ?? "0"
        let encodedCategory = challenge.category.flatMap(encodeText) ?? "0"
        return [
            "KA4",
            String(challenge.seed, radix: 36, uppercase: true),
            String(challenge.questionIDs.count, radix: 36, uppercase: true),
            String(challenge.totalTime, radix: 36, uppercase: true),
            String(challenge.maxDifficulty, radix: 36, uppercase: true),
            String(challenge.passLimit, radix: 36, uppercase: true),
            encodedCategory,
            encodedName
        ].joined(separator: "-")
    }

    func shareURL(for challenge: PrivateChallenge) -> URL {
        let code = shareCode(for: challenge)
        var components = URLComponents()
        components.scheme = "kelimeavi"
        components.host = "private"
        components.queryItems = [URLQueryItem(name: "c", value: code)]
        return components.url ?? URL(string: "kelimeavi://private?c=\(code)")!
    }

    func challenge(from text: String) -> PrivateChallenge? {
        let rawCode = extractCode(from: text)
        if let compactChallenge = challenge(fromCompactCode: rawCode) {
            return compactChallenge
        }

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

    func hasJoined(_ challenge: PrivateChallenge) -> Bool {
        joinedIDs.contains(challenge.id.uuidString)
    }

    func markJoined(_ challenge: PrivateChallenge) {
        var ids = joinedIDs
        ids.insert(challenge.id.uuidString)
        defaults.set(Array(ids), forKey: joinedKey)
    }

    private func extractCode(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "c" || $0.name == "code" })?.value else {
            return trimmed
        }
        return code
    }

    private var joinedIDs: Set<String> {
        Set(defaults.stringArray(forKey: joinedKey) ?? [])
    }

    private func challenge(fromCompactCode code: String) -> PrivateChallenge? {
        let parts = code.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-").map(String.init)
        guard (parts.count == 5 || parts.count == 6 || parts.count == 7 || parts.count == 8) else {
            return nil
        }

        let version = parts[0].uppercased()
        guard (version == "KA1" || version == "KA2" || version == "KA3" || version == "KA4"),
              let seed = UInt64(parts[1].uppercased(), radix: 36),
              let count = Int(parts[2].uppercased(), radix: 36),
              let time = Int(parts[3].uppercased(), radix: 36),
              let difficulty = Int(parts[4].uppercased(), radix: 36) else {
            return nil
        }

        let safeCount = min(max(count, 6), 16)
        let safeTime = min(max(time, 90), 300)
        let safeDifficulty = min(max(difficulty, 2), 5)
        let category: String?
        let creatorName: String
        let safePassLimit: Int

        if version == "KA4", parts.count == 8 {
            safePassLimit = min(max(Int(parts[5].uppercased(), radix: 36) ?? 0, 0), 5)
            category = parts[6] == "0" ? nil : decodeText(parts[6])
            creatorName = decodeText(parts[7]) ?? "Arkadaş"
        } else if version == "KA3", parts.count == 7 {
            safePassLimit = 0
            category = parts[5] == "0" ? nil : decodeText(parts[5])
            creatorName = decodeText(parts[6]) ?? "Arkadaş"
        } else {
            safePassLimit = 0
            category = version == "KA2" && parts.count == 6 ? decodeText(parts[5]) : nil
            creatorName = "Arkadaş"
        }

        let questions = questionService.privateChallengeQuestions(
            count: safeCount,
            maxDifficulty: safeDifficulty,
            seed: seed,
            category: category
        )

        return PrivateChallenge(
            id: deterministicID(seed: seed, questionCount: questions.count, totalTime: safeTime, maxDifficulty: safeDifficulty, passLimit: safePassLimit, category: category),
            creatorName: creatorName,
            title: category.map { "\(creatorName) \($0) kategorisinde meydan okuyor" } ?? "\(creatorName) meydan okuyor",
            questionIDs: questions.map(\.id),
            totalTime: safeTime,
            maxDifficulty: safeDifficulty,
            passLimit: safePassLimit,
            category: category,
            seed: seed
        )
    }

    private func deterministicID(seed: UInt64, questionCount: Int, totalTime: Int, maxDifficulty: Int, passLimit: Int, category: String?) -> UUID {
        let categoryHash = stableHash(category?.turkishGameNormalized() ?? "")
        let mixed = seed
            ^ (UInt64(questionCount) << 48)
            ^ (UInt64(totalTime) << 24)
            ^ (UInt64(maxDifficulty) << 8)
            ^ UInt64(passLimit)
            ^ categoryHash
        let high = mixed
        let low = mixed &* 0x9E3779B97F4A7C15
        let uuidString = String(
            format: "%08X-%04X-%04X-%04X-%012llX",
            UInt32(high >> 32),
            UInt16((high >> 16) & 0xFFFF),
            UInt16(high & 0xFFFF),
            UInt16(low >> 48),
            low & 0x0000FFFFFFFFFFFF
        )
        return UUID(uuidString: uuidString) ?? UUID()
    }

    private func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }

    private func sanitizedCategory(_ category: String?) -> String? {
        let trimmed = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != "Karışık" else { return nil }
        return trimmed
    }

    private func encodeText(_ text: String) -> String? {
        text.data(using: .utf8)?
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "_")
            .replacingOccurrences(of: "/", with: ".")
            .replacingOccurrences(of: "=", with: "")
    }

    private func decodeText(_ encoded: String) -> String? {
        var normalized = encoded
            .replacingOccurrences(of: "_", with: "+")
            .replacingOccurrences(of: ".", with: "/")
        let remainder = normalized.count % 4
        if remainder > 0 {
            normalized.append(String(repeating: "=", count: 4 - remainder))
        }
        guard let data = Data(base64Encoded: normalized) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
