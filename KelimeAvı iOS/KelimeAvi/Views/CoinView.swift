import SwiftUI

struct CoinIcon: View {
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [GameTheme.yellow, Color(red: 1.0, green: 0.48, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(.white.opacity(0.42), lineWidth: max(1, size * 0.07))
            Text("M")
                .font(.system(size: size * 0.52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: GameTheme.yellow.opacity(0.35), radius: size * 0.18, y: size * 0.10)
    }
}

struct CoinAmountBadge: View {
    let amount: Int
    var title: String? = nil
    var prominence: CoinBadgeProminence = .normal

    var body: some View {
        HStack(spacing: prominence == .large ? 10 : 7) {
            CoinIcon(size: prominence == .large ? 34 : 24)

            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    Text(title)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white.opacity(0.70))
                }
                Text("\(amount) altın")
                    .font((prominence == .large ? Font.headline : Font.subheadline).weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, prominence == .large ? 16 : 12)
        .frame(height: prominence == .large ? 54 : 40)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.28), GameTheme.orange.opacity(0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(GameTheme.yellow.opacity(0.55), lineWidth: prominence == .large ? 2 : 1.5)
        )
    }
}

enum CoinBadgeProminence {
    case normal
    case large
}
