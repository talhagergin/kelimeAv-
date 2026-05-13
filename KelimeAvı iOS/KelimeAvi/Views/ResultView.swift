import SwiftUI

struct ResultView: View {
    let result: GameResult
    let onReplay: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Oyun Bitti")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            if result.stars > 0 {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < result.stars ? "star.fill" : "star")
                            .font(.largeTitle)
                            .foregroundStyle(GameTheme.yellow)
                    }
                }
            }

            VStack(spacing: 10) {
                ResultRow(title: "Toplam skor", value: "\(result.score)")
                ResultRow(title: "Doğru", value: "\(result.correctCount)")
                ResultRow(title: "Yanlış", value: "\(result.wrongCount)")
                ResultRow(title: "Kullanılan harf", value: "\(result.revealedLetterCount)")
                if result.maxCombo > 1 {
                    ResultRow(title: "En iyi kombo", value: "\(result.maxCombo) doğru")
                }
            }
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))

            if !result.unlockedBadges.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Yeni Rozet")
                            .font(.headline.weight(.black))
                            .foregroundStyle(GameTheme.yellow)
                        Spacer()
                        Text("+\(result.badgeCoinReward) altın")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.white)
                    }

                    ForEach(result.unlockedBadges) { badge in
                        HStack {
                            Label(badge.title, systemImage: badge.iconName)
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("+\(badge.rewardCoins)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(GameTheme.yellow)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))
            }

            if !result.personalMoments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rekor Anları")
                        .font(.headline.weight(.black))
                        .foregroundStyle(GameTheme.yellow)

                    ForEach(result.personalMoments, id: \.self) { moment in
                        Label(moment, systemImage: "sparkles")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))
            }

            VStack(spacing: 12) {
                if result.mode != GameMode.daily.rawValue {
                    Button(action: onReplay) {
                        Label("Tekrar Oyna", systemImage: "arrow.clockwise")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                }

                Button(action: onMenu) {
                    Label("Ana Menüye Dön", systemImage: "house.fill")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(24)
    }
}

private struct ResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
        }
    }
}
