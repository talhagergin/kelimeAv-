import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()

    let onClassic: () -> Void
    let onChallenge: () -> Void
    let onPrivateChallenge: () -> Void
    let onShop: () -> Void
    let onScores: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("Kelime Avı")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("En yüksek klasik skor: \(viewModel.classicHighScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GameTheme.yellow)
                Label("\(viewModel.coins) altın", systemImage: "bitcoinsign.circle.fill")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 14) {
                MenuButton(title: "Klasik Mod", icon: "timer", action: onClassic)
                MenuButton(title: "Challenge Mod", icon: "star.fill", action: onChallenge)
                MenuButton(title: "Private Challenge", icon: "person.2.fill", action: onPrivateChallenge)
                MenuButton(title: "Mağaza", icon: "cart.fill", action: onShop)
                MenuButton(title: "Skorlar", icon: "chart.bar.fill", action: onScores)
                MenuButton(title: "Ayarlar", icon: "gearshape.fill", action: onSettings)
            }
            .padding(.horizontal, 26)

            Spacer()
        }
        .onAppear { viewModel.refresh() }
    }
}

private struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 28)
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
            }
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(GameTheme.blue.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GameTheme.yellow.opacity(0.8), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
