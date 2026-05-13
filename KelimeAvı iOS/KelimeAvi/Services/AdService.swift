import Foundation
import Combine
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

enum AdConfiguration {
    static let sampleApplicationID = "ca-app-pub-2025425313677693~5538270893"
    static let bannerAdUnitID = "ca-app-pub-2025425313677693/9285944211"
    static let interstitialAdUnitID = "ca-app-pub-2025425313677693/5580609286"
    static let rewardedAdUnitID = "ca-app-pub-2025425313677693/2485655588"
}

@MainActor
final class AdService: NSObject, ObservableObject {
    static let shared = AdService()

    @Published private(set) var isRewardedAdReady = false

    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    private var rewardedDidEarnReward = false
    private var rewardedUnavailableHandler: (() -> Void)?
    #endif

    private override init() {}

    func start() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        Task {
            await loadRewardedAd()
            await loadInterstitialAd()
        }
        #endif
    }

    func showRewardedAd(onReward: @escaping () -> Void, onUnavailable: @escaping () -> Void) {
        #if canImport(GoogleMobileAds)
        guard let rewardedAd else {
            onUnavailable()
            Task { await loadRewardedAd() }
            return
        }
        guard Self.rootViewController() != nil else {
            onUnavailable()
            Task { await loadRewardedAd() }
            return
        }

        self.rewardedAd = nil
        isRewardedAdReady = false
        rewardedDidEarnReward = false
        rewardedUnavailableHandler = onUnavailable
        rewardedAd.fullScreenContentDelegate = self
        rewardedAd.present(from: Self.rootViewController()) {
            self.rewardedDidEarnReward = true
            onReward()
        }
        Task { await loadRewardedAd() }
        #else
        onUnavailable()
        #endif
    }

    func refreshRewardedAd() {
        #if canImport(GoogleMobileAds)
        guard !isRewardedAdReady else { return }
        Task { await loadRewardedAd() }
        #endif
    }

    func showInterstitialAd(onFinished: @escaping () -> Void) {
        #if canImport(GoogleMobileAds)
        guard let interstitialAd else {
            onFinished()
            Task { await loadInterstitialAd() }
            return
        }

        self.interstitialAd = nil
        interstitialAd.present(from: Self.rootViewController())
        Task {
            try? await Task.sleep(for: .seconds(1))
            await loadInterstitialAd()
            onFinished()
        }
        #else
        onFinished()
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func loadRewardedAd() async {
        do {
            rewardedAd = try await RewardedAd.load(
                with: AdConfiguration.rewardedAdUnitID,
                request: Request()
            )
            isRewardedAdReady = true
        } catch {
            rewardedAd = nil
            isRewardedAdReady = false
        }
    }

    private func loadInterstitialAd() async {
        do {
            interstitialAd = try await InterstitialAd.load(
                with: AdConfiguration.interstitialAdUnitID,
                request: Request()
            )
        } catch {
            interstitialAd = nil
        }
    }

    static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if !rewardedDidEarnReward {
            rewardedUnavailableHandler?()
        }
        rewardedUnavailableHandler = nil
        rewardedDidEarnReward = false
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedUnavailableHandler?()
        rewardedUnavailableHandler = nil
        rewardedDidEarnReward = false
        Task { await loadRewardedAd() }
    }
}
#endif

final class AdPlacementPolicy {
    static let shared = AdPlacementPolicy()

    private let gameAttemptCountKey = "adPolicy.gameAttemptCount"
    private var completedGamesSinceLastInterstitial = 0
    private let defaults = UserDefaults.standard

    private init() {}

    func shouldShowInterstitialAfterGameAttempt() -> Bool {
        let nextCount = defaults.integer(forKey: gameAttemptCountKey) + 1
        defaults.set(nextCount, forKey: gameAttemptCountKey)
        return nextCount.isMultiple(of: 5)
    }

    func shouldOfferSoftAdBreak() -> Bool {
        completedGamesSinceLastInterstitial += 1
        guard completedGamesSinceLastInterstitial >= 2 else { return false }
        completedGamesSinceLastInterstitial = 0
        return true
    }
}
