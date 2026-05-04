import SwiftUI

struct JokerBarView: View {
    @ObservedObject var viewModel: GameViewModel
    var onPick: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Jokerler")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
                Spacer()
                Text("Haklarını mağazadan al")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(GameTheme.yellow.opacity(0.95))
            }

            if let message = viewModel.coinMessage {
                HStack(spacing: 8) {
                    Text(message)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        viewModel.earnRewardedAdCoins()
                    } label: {
                        Text("Reklam")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(GameTheme.orange, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(9)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    viewModel.clearCoinMessage()
                }
            }

            HStack(spacing: 8) {
                ForEach(JokerType.allCases) { joker in
                    Button {
                        viewModel.useJoker(joker)
                        onPick()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: joker.iconName)
                                .font(.headline.weight(.black))
                            Text(joker.title)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.48)
                            Text("\(viewModel.inventoryCount(for: joker)) hak")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(GameTheme.yellow)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
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

    private func jokerColor(_ joker: JokerType) -> Color {
        viewModel.usedJokers.contains(joker) ? .gray.opacity(0.5) : GameTheme.blue.opacity(0.85)
    }
}
