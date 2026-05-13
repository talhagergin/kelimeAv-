import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

struct AdBannerView: View {
    @Binding var isLoaded: Bool

    var body: some View {
        GeometryReader { proxy in
            #if canImport(GoogleMobileAds)
            GoogleMobileAdsBanner(width: proxy.size.width, isLoaded: $isLoaded)
            #else
            Color.clear
                .onAppear {
                    isLoaded = false
                }
            #endif
        }
        .accessibilityLabel("Reklam")
    }
}

#if canImport(GoogleMobileAds)
private struct GoogleMobileAdsBanner: UIViewRepresentable {
    let width: CGFloat
    @Binding var isLoaded: Bool

    func makeUIView(context: Context) -> BannerView {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: max(width, 320))
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AdConfiguration.bannerAdUnitID
        banner.rootViewController = AdService.rootViewController()
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = currentOrientationAnchoredAdaptiveBanner(width: max(width, 320))
        uiView.rootViewController = AdService.rootViewController()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding private var isLoaded: Bool

        init(isLoaded: Binding<Bool>) {
            _isLoaded = isLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            isLoaded = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            isLoaded = false
        }
    }
}
#endif
