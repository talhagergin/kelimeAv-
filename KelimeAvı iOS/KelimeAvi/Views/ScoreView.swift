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

            Text("Skorlar")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                ScoreCard(title: "Klasik Mod", value: "\(scoreService.classicHighScore) puan", icon: "timer")

                ForEach(1...5, id: \.self) { level in
                    ScoreCard(
                        title: "Challenge Bölüm \(level)",
                        value: String(repeating: "★", count: scoreService.stars(forLevel: level)).padding(toLength: 3, withPad: "☆", startingAt: 0),
                        icon: "star.fill"
                    )
                }
            }

            Spacer()
        }
        .padding(20)
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
