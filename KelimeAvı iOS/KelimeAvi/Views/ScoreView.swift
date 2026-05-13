import SwiftUI

struct ScoreView: View {
    private let scoreService = ScoreService()
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 72)

            Text("Skorlar")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                ScoreCard(title: "Klasik Mod", value: "\(scoreService.classicHighScore) puan", icon: "timer")
                ScoreCard(title: "Günlük Seri", value: "\(scoreService.dailyStreak()) / 10 gün", icon: "flame.fill")

                ForEach(1...5, id: \.self) { level in
                    ScoreCard(
                        title: "Challenge Bölüm \(level)",
                        value: String(repeating: "★", count: scoreService.stars(forLevel: level)).padding(toLength: 3, withPad: "☆", startingAt: 0),
                        icon: "star.fill"
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Rozetler")
                        .font(.headline.weight(.black))
                        .foregroundStyle(GameTheme.yellow)

                    ForEach(BadgeType.allCases) { badge in
                        BadgeScoreRow(badge: badge, isUnlocked: scoreService.isBadgeUnlocked(badge))
                    }
                }
                .padding(16)
                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))
            }

            Spacer()
        }
        .padding(20)
        .swipeBackGesture(onBack)
    }
}

private struct BadgeScoreRow: View {
    let badge: BadgeType
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: badge.iconName)
                .foregroundStyle(isUnlocked ? GameTheme.yellow : .white.opacity(0.35))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(badge.title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.50))
                Text(badge.description)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer()
            Text("+\(badge.rewardCoins)")
                .font(.caption.weight(.black))
                .foregroundStyle(isUnlocked ? GameTheme.yellow : .white.opacity(0.28))
            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .foregroundStyle(isUnlocked ? .green : .white.opacity(0.32))
        }
    }
}

private struct ScoreCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(GameTheme.yellow)
                .frame(width: 30)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}
