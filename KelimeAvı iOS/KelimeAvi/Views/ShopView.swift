import SwiftUI

struct ShopView: View {
    @State private var coins: Int = ScoreService().coins
    @State private var inventory: [JokerType: Int] = [:]
    @State private var message = "Joker haklarını buradan al, oyun içinde sadece kullan."

    private let scoreService = ScoreService()
    private let jokerPrice = 12
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            header

            Text("Mağaza")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(JokerType.allCases) { joker in
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

            Text(message)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                scoreService.addCoins(6)
                refresh()
                message = "Ödüllü reklam simülasyonu: +6 altın eklendi."
            } label: {
                Label("Reklam İzle ve Altın Kazan", systemImage: "play.rectangle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(20)
        .onAppear(perform: refresh)
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

            Label("\(coins)", systemImage: "bitcoinsign.circle.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(GameTheme.yellow)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(.black.opacity(0.22), in: Capsule())
        }
    }

    private func buy(_ joker: JokerType) {
        guard scoreService.spendCoins(jokerPrice) else {
            message = "Yetersiz altın. Reklam izleyerek altın kazanabilirsin."
            refresh()
            return
        }
        scoreService.addInventory(1, for: joker)
        refresh()
        message = "\(joker.title) hakkı alındı."
    }

    private func refresh() {
        coins = scoreService.coins
        inventory = Dictionary(uniqueKeysWithValues: JokerType.allCases.map { ($0, scoreService.inventoryCount(for: $0)) })
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
                Label("\(price)", systemImage: "bitcoinsign.circle.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(canBuy ? GameTheme.blue : .gray.opacity(0.45), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
        }
        .padding(13)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }
}
