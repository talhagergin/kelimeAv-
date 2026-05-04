import SwiftUI

struct ChallengeAdBreakView: View {
    let coinReward: Int
    let onRewardedAd: () -> Void
    let onContinue: () -> Void
    @State private var adWatched = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 58, weight: .black))
                    .foregroundStyle(GameTheme.yellow)

                Text("Reklam Molası")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Challenge bölümü tamamlandı. Bölüm ödülü: \(coinReward) altın. Joker ekonomisi zor tutuldu; ekstra altın için ödüllü reklam izleyebilirsin.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            }
            .padding(22)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 22))

            VStack(spacing: 12) {
                Button {
                    adWatched = true
                    onRewardedAd()
                } label: {
                    Label(adWatched ? "+6 altın alındı" : "Ödüllü Reklam İzle (+6)", systemImage: "bitcoinsign.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(adWatched)
                .opacity(adWatched ? 0.65 : 1)

                Button(action: onContinue) {
                    Label("Sonuçları Göster", systemImage: "arrow.right.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(24)
    }
}
