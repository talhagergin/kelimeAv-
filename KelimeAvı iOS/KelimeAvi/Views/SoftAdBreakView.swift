import SwiftUI

struct SoftAdBreakView: View {
    let onContinue: () -> Void
    @State private var didWatch = false
    @State private var isShowingAd = false
    @State private var isBannerLoaded = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(GameTheme.yellow)

                Text("Kısa Reklam")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Oyun aralarında gösterilir. Devam et butonu her zaman açık kalır.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                AdBannerView(isLoaded: $isBannerLoaded)
                    .frame(height: isBannerLoaded ? 50 : 1)
                    .opacity(isBannerLoaded ? 1 : 0)
                    .padding(.top, 6)
            }
            .padding(22)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 22))

            Button {
                isShowingAd = true
                AdService.shared.showInterstitialAd {
                    didWatch = true
                    isShowingAd = false
                    onContinue()
                }
            } label: {
                Label(continueTitle, systemImage: "arrow.right.circle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(isShowingAd)
            .opacity(isShowingAd ? 0.65 : 1)

            Spacer()
        }
        .padding(24)
    }

    private var continueTitle: String {
        if isShowingAd { return "Reklam Açılıyor" }
        return didWatch ? "Devam Ediliyor" : "Devam Et"
    }
}
