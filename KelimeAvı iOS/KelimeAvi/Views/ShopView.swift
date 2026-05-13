import SwiftUI

struct ShopView: View {
    @ObservedObject private var adService = AdService.shared
    @State private var coins: Int = ScoreService().coins
    @State private var inventory: [JokerType: Int] = [:]
    @State private var selectedSkin: TileSkin = .classicBlue
    @State private var message = "Joker haklarını buradan al, oyun içinde sadece kullan."
    @State private var toastMessage: String?
    @State private var isRequestingRewardedAd = false
    @State private var showsAllSkins = false

    private let scoreService = ScoreService()
    private let soundService = SoundService()
    private let jokerPrice = 12
    private let collapsedSkinCount = 4
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("Mağaza")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    VStack(spacing: 10) {
                        ForEach(visibleJokers) { joker in
                            ShopJokerRow(
                                joker: joker,
                                count: inventory[joker, default: 0],
                                price: jokerPrice,
                                canBuy: coins >= jokerPrice
                            ) {
                                buy(joker)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Harf Kutusu Skinleri")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(visibleSkins) { skin in
                                ShopSkinCard(
                                    skin: skin,
                                    isUnlocked: scoreService.isTileSkinUnlocked(skin),
                                    isSelected: selectedSkin == skin,
                                    canBuy: coins >= skin.price
                                ) {
                                    handleSkinTap(skin)
                                }
                            }
                        }

                        if TileSkin.allCases.count > collapsedSkinCount {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                    showsAllSkins.toggle()
                                }
                            } label: {
                                Label(showsAllSkins ? "Daha Az Göster" : "Daha Fazla Göster", systemImage: showsAllSkins ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(.white.opacity(0.14), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))

                    Text(message)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                }
            }

            if let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                guard adService.isRewardedAdReady else {
                    showToast("Reklam hazır olduğunda bu buton aktifleşir.")
                    AdService.shared.refreshRewardedAd()
                    return
                }
                isRequestingRewardedAd = true
                AdService.shared.showRewardedAd {
                    scoreService.addCoins(6)
                    refresh()
                    isRequestingRewardedAd = false
                    showToast("Reklam ödülü: +6 altın eklendi.")
                } onUnavailable: {
                    isRequestingRewardedAd = false
                    soundService.playInsufficientCoins()
                    showToast("Reklam hazır değil. Biraz sonra tekrar deneyebilirsin.")
                }
            } label: {
                Label(rewardedAdButtonTitle, systemImage: adService.isRewardedAdReady ? "play.rectangle.fill" : "clock.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(adService.isRewardedAdReady ? GameTheme.orange : .white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(isRequestingRewardedAd || !adService.isRewardedAdReady)
            .opacity(isRequestingRewardedAd || !adService.isRewardedAdReady ? 0.68 : 1)
        }
        .padding(20)
        .onAppear {
            refresh()
            AdService.shared.refreshRewardedAd()
        }
        .swipeBackGesture(onBack)
    }

    private var header: some View {
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

            CoinAmountBadge(amount: coins)
        }
    }

    private func buy(_ joker: JokerType) {
        guard scoreService.spendCoins(jokerPrice) else {
            soundService.playInsufficientCoins()
            showToast("Yetersiz altın. Reklam izleyerek altın kazanabilirsin.")
            refresh()
            return
        }
        scoreService.addInventory(1, for: joker)
        soundService.playPurchase()
        refresh()
        showToast("\(joker.title) hakkı alındı.")
    }

    private func refresh() {
        coins = scoreService.coins
        selectedSkin = scoreService.selectedTileSkin
        inventory = Dictionary(uniqueKeysWithValues: visibleJokers.map { ($0, scoreService.inventoryCount(for: $0)) })
    }

    private func handleSkinTap(_ skin: TileSkin) {
        if scoreService.isTileSkinUnlocked(skin) {
            scoreService.selectTileSkin(skin)
            soundService.playJoker()
            refresh()
            showToast("\(skin.title) seçildi.")
            return
        }

        if scoreService.unlockTileSkin(skin) {
            scoreService.selectTileSkin(skin)
            soundService.playPurchase()
            refresh()
            showToast("\(skin.title) açıldı ve seçildi.")
        } else {
            soundService.playInsufficientCoins()
            refresh()
            showToast("Yetersiz altın. Reklam izleyerek kazanabilirsin.")
        }
    }

    private func showToast(_ text: String) {
        message = text
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            toastMessage = text
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.2)) {
                if toastMessage == text {
                    toastMessage = nil
                }
            }
        }
    }

    private var visibleJokers: [JokerType] {
        JokerType.allCases.filter { $0 != .revealLetter }
    }

    private var visibleSkins: [TileSkin] {
        let skins = Array(TileSkin.allCases)
        guard !showsAllSkins else { return skins }
        return Array(skins.prefix(collapsedSkinCount))
    }

    private var rewardedAdButtonTitle: String {
        if isRequestingRewardedAd { return "Reklam Hazırlanıyor" }
        return adService.isRewardedAdReady ? "Reklam İzle ve Altın Kazan" : "Reklam Hazır Değil"
    }
}

private struct ShopSkinCard: View {
    let skin: TileSkin
    let isUnlocked: Bool
    let isSelected: Bool
    let canBuy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 7)
                            .fill(previewColor)
                            .frame(width: 25, height: 25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(GameTheme.yellow.opacity(0.85), lineWidth: 1.5)
                            )
                            .overlay {
                                Text(["K", "A", "V"][index])
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.white)
                            }
                    }
                }

                Text(skin.title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(statusText)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(isSelected ? GameTheme.yellow : .white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.black.opacity(isSelected ? 0.28 : 0.14), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? GameTheme.yellow : .white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isUnlocked || canBuy ? 1 : 0.55)
            .overlay(alignment: .topTrailing) {
                if skin.isPatterned {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                        .padding(7)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var statusText: String {
        if isSelected { return "Seçili" }
        if isUnlocked { return "Seç" }
        return "\(skin.price) altın"
    }

    private var previewColor: Color {
        switch skin {
        case .classicBlue: return GameTheme.blue
        case .royalPurple: return Color(red: 0.45, green: 0.16, blue: 0.82)
        case .sunset: return GameTheme.orange
        case .mint: return Color(red: 0.10, green: 0.70, blue: 0.56)
        case .ruby: return Color(red: 0.82, green: 0.05, blue: 0.18)
        case .emerald: return Color(red: 0.02, green: 0.62, blue: 0.30)
        case .ocean: return Color(red: 0.04, green: 0.44, blue: 0.86)
        case .lemon: return Color(red: 0.94, green: 0.70, blue: 0.08)
        case .graphite: return Color(red: 0.18, green: 0.18, blue: 0.23)
        case .candy: return Color(red: 0.88, green: 0.22, blue: 0.72)
        case .galaxy: return Color(red: 0.18, green: 0.07, blue: 0.56)
        case .neon: return Color(red: 0.04, green: 0.74, blue: 0.82)
        case .ice: return Color(red: 0.30, green: 0.70, blue: 0.94)
        case .rose: return Color(red: 0.82, green: 0.18, blue: 0.42)
        }
    }
}

private extension TileSkin {
    var isPatterned: Bool {
        switch self {
        case .candy, .galaxy, .neon, .ice:
            return true
        default:
            return false
        }
    }
}

private struct ShopJokerRow: View {
    let joker: JokerType
    let count: Int
    let price: Int
    let canBuy: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: joker.iconName)
                .font(.title3.weight(.black))
                .foregroundStyle(GameTheme.yellow)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(joker.title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text("\(count) hak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Button(action: onBuy) {
                HStack(spacing: 6) {
                    CoinIcon(size: 20)
                    Text("\(price)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(canBuy ? GameTheme.blue : .gray.opacity(0.45), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(13)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }
}
