import SwiftUI

@main
struct KelimeAviApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private enum AppScreen {
    case splash
    case onboarding
    case menu
    case classic
    case challenge
    case shop
    case scores
    case settings
}

private struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var screen: AppScreen = .splash

    var body: some View {
        ZStack {
            GameTheme.background.ignoresSafeArea()

            switch screen {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = hasSeenOnboarding ? .menu : .onboarding
                    }
                }
            case .onboarding:
                OnboardingView {
                    hasSeenOnboarding = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        screen = .menu
                    }
                }
            case .menu:
                MainMenuView(
                    onClassic: { screen = .classic },
                    onChallenge: { screen = .challenge },
                    onShop: { screen = .shop },
                    onScores: { screen = .scores },
                    onSettings: { screen = .settings }
                )
            case .classic:
                GameView(viewModel: GameViewModel(mode: .classic)) {
                    screen = .menu
                }
            case .challenge:
                GameView(viewModel: GameViewModel(mode: .challenge, level: 1)) {
                    screen = .menu
                }
            case .shop:
                ShopView {
                    screen = .menu
                }
            case .scores:
                ScoreView {
                    screen = .menu
                }
            case .settings:
                SettingsView {
                    screen = .menu
                }
            }
        }
    }
}

enum GameTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.06, blue: 0.34),
            Color(red: 0.29, green: 0.14, blue: 0.58),
            Color(red: 0.50, green: 0.18, blue: 0.48),
            Color(red: 0.96, green: 0.47, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blue = Color(red: 0.32, green: 0.34, blue: 0.90)
    static let yellow = Color(red: 1.0, green: 0.76, blue: 0.16)
    static let orange = Color(red: 1.0, green: 0.39, blue: 0.14)
    static let panel = Color.white.opacity(0.14)
}
