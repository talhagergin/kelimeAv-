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
            }
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 12) {
                Button(action: onReplay) {
                    Label("Tekrar Oyna", systemImage: "arrow.clockwise")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
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
