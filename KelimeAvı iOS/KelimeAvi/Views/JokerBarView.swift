import SwiftUI

struct JokerBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var adService = AdService.shared
    var onPick: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Jokerler")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
                Spacer()
                Text("Haklarını mağazadan al")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GameTheme.yellow.opacity(0.95))
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .buttonStyle(.plain)
            }

            if let message = viewModel.coinMessage {
                HStack(spacing: 8) {
                    Text(message)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        guard adService.isRewardedAdReady else {
                            viewModel.markRewardedAdUnavailable()
                            AdService.shared.refreshRewardedAd()
                            return
                        }
                        AdService.shared.showRewardedAd {
                            viewModel.grantRewardedAdCoins()
                        } onUnavailable: {
                            viewModel.markRewardedAdUnavailable()
                        }
                    } label: {
                        Text(adService.isRewardedAdReady ? "Reklam" : "Hazır Değil")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(GameTheme.orange, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!adService.isRewardedAdReady)
                    .opacity(adService.isRewardedAdReady ? 1 : 0.65)
                }
                .padding(9)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    viewModel.clearCoinMessage()
                }
            }

            LazyVGrid(columns: jokerColumns, spacing: 10) {
                ForEach(visibleJokers) { joker in
                    Button {
                        viewModel.useJoker(joker)
                        onPick()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: joker.iconName)
                                .font(.title3.weight(.black))
                            Text(joker.title)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.58)
                            Text("\(viewModel.inventoryCount(for: joker)) hak")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(GameTheme.yellow)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 66)
                        .background(
                            LinearGradient(
                                colors: [jokerColor(joker), jokerColor(joker).opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isJokerEnabled(joker))
                    .opacity(viewModel.isJokerEnabled(joker) ? 1 : 0.36)
                }
            }
        }
    }

    private var jokerColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private func jokerColor(_ joker: JokerType) -> Color {
        viewModel.usedJokers.contains(joker) ? .gray.opacity(0.5) : GameTheme.blue.opacity(0.85)
    }

    private var visibleJokers: [JokerType] {
        JokerType.allCases.filter { $0 != .revealLetter }
    }
}
