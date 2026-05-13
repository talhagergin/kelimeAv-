import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()

    let onClassic: () -> Void
    let onQuickTour: () -> Void
    let onDaily: () -> Void
    let onChallenge: () -> Void
    let onCategory: () -> Void
    let onPrivateChallenge: () -> Void
    let onShop: () -> Void
    let onScores: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 8) {
                AnimatedTitleLogo()
                Text("En yüksek klasik skor: \(viewModel.classicHighScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GameTheme.yellow)
                CoinAmountBadge(amount: viewModel.coins, title: "Cüzdan", prominence: .large)
            }

            dailyQuestCard
                .padding(.horizontal, 26)

            VStack(spacing: 10) {
                MenuButton(title: "Klasik Mod", icon: "timer", action: onClassic)
                MenuButton(title: "Hızlı Tur", icon: "bolt.fill", action: onQuickTour)
                MenuButton(title: "Challenge Mod", icon: "star.fill", action: onChallenge)
                MenuButton(title: "Kategori Haritası", icon: "map.fill", action: onCategory)
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

    @ViewBuilder
    private var dailyQuestCard: some View {
        if viewModel.isDailyCompletedToday {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Günlük av tamam")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text("Seri: \(viewModel.dailyStreak) / 10 gün")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
        } else {
            Button(action: onDaily) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 48)
                        .background(GameTheme.yellow, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Günlük Kelime Avı")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text("Bugünün 5 sorusu hazır")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    Image(systemName: "play.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .frame(height: 68)
                .background(GameTheme.orange.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(GameTheme.yellow.opacity(0.82), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct AnimatedTitleLogo: View {
    private let letters = Array("KELİME AVI").map(String.init)

    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate

            HStack(spacing: 1) {
                ForEach(letters.indices, id: \.self) { index in
                    let letter = letters[index]
                    let lift = sin(phase * 2.2 + Double(index) * 0.42) * 3.0

                    Text(letter)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(letter == " " ? .clear : .white)
                        .shadow(color: GameTheme.yellow.opacity(0.72), radius: letter == " " ? 0 : 8, y: 2)
                        .offset(y: letter == " " ? 0 : lift)
                        .scaleEffect(letter == " " ? 1 : 1 + CGFloat(max(0, lift)) * 0.006)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [GameTheme.blue.opacity(0.85), GameTheme.orange.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(GameTheme.yellow.opacity(0.86), lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkles")
                    .font(.headline.weight(.black))
                    .foregroundStyle(GameTheme.yellow)
                    .offset(x: 6, y: -6)
                    .rotationEffect(.degrees(sin(phase * 2.0) * 10))
            }
        }
        .frame(height: 74)
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
            .frame(height: 54)
            .background(GameTheme.blue.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GameTheme.yellow.opacity(0.8), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
