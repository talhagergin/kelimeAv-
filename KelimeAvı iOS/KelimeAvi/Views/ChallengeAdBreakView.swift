import SwiftUI

struct ChallengeAdBreakView: View {
    let coinReward: Int
    let onRewardedAd: () -> Void
    let onContinue: () -> Void
    @ObservedObject private var adService = AdService.shared
    @State private var adWatched = false
    @State private var adMessage: String?
    @State private var isRequestingAd = false

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

                Text("Bölüm tamamlandı. Bölüm ödülü: \(coinReward) altın. Joker ekonomisi zor tutuldu; ekstra altın için ödüllü reklam izleyebilirsin.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                if let adMessage {
                    Text(adMessage)
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(22)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 22))

            VStack(spacing: 12) {
                Button {
                    guard adService.isRewardedAdReady else {
                        adMessage = "Reklam hazır olduğunda bu buton aktifleşir."
                        AdService.shared.refreshRewardedAd()
                        return
                    }
                    isRequestingAd = true
                    AdService.shared.showRewardedAd {
                        adWatched = true
                        isRequestingAd = false
                        adMessage = "+6 altın hesabına eklendi."
                        onRewardedAd()
                    } onUnavailable: {
                        isRequestingAd = false
                        adMessage = "Reklam hazır değil. Biraz sonra tekrar dene."
                }
            } label: {
                    HStack(spacing: 8) {
                        CoinIcon(size: 24)
                        Text(rewardButtonTitle)
                    }
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(adService.isRewardedAdReady ? GameTheme.orange : .white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(adWatched || isRequestingAd || !adService.isRewardedAdReady)
                .opacity(adWatched || isRequestingAd || !adService.isRewardedAdReady ? 0.65 : 1)

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
        .onAppear {
            AdService.shared.refreshRewardedAd()
        }
    }

    private var rewardButtonTitle: String {
        if isRequestingAd { return "Reklam Hazırlanıyor" }
        if !adService.isRewardedAdReady { return "Reklam Hazır Değil" }
        return adWatched ? "+6 altın alındı" : "Ödüllü Reklam İzle (+6)"
    }
}
