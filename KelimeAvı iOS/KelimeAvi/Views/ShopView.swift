import SwiftUI

struct ShopView: View {
    @State private var coins: Int = ScoreService().coins
    @State private var message = "Challenge moddan az miktarda altın kazanılır."
    private let scoreService = ScoreService()
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 18) {
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

            Text("Mağaza")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                ShopRow(title: "Joker Kullanımı", subtitle: "Oyun içinde her joker 12 altın harcar.", icon: "wand.and.stars")
                ShopRow(title: "Challenge Ödülleri", subtitle: "1 yıldız: 1, 2 yıldız: 3, 3 yıldız: 5 altın.", icon: "star.fill")
                ShopRow(title: "Reklam Ödülü", subtitle: "Ödüllü reklam izleyerek +6 altın kazan.", icon: "play.rectangle.fill")
            }

            Text(message)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                scoreService.addCoins(6)
                coins = scoreService.coins
                message = "Ödüllü reklam simülasyonu: +6 altın eklendi."
            } label: {
                Label("Reklam İzle ve Altın Kazan", systemImage: "bitcoinsign.circle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
    }
}

private struct ShopRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(GameTheme.yellow)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()
        }
        .padding(15)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}
