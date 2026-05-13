import SwiftUI

@main
struct KelimeAviApp: App {
    init() {
        AdService.shared.start()
    }

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
    case classicSetup
    case classic(Int)
    case quickTour
    case daily
    case challengeSetup
    case challenge(Int)
    case categorySelection
    case categoryGame(String, Int, Int)
    case privateChallengeSetup
    case privateChallengeGame(PrivateChallenge)
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
                    onClassic: { screen = .classicSetup },
                    onQuickTour: { screen = .quickTour },
                    onDaily: {
                        guard !ScoreService().isDailyCompletedToday(date: Date()) else { return }
                        screen = .daily
                    },
                    onChallenge: { screen = .challengeSetup },
                    onCategory: { screen = .categorySelection },
                    onPrivateChallenge: { screen = .privateChallengeSetup },
                    onShop: { screen = .shop },
                    onScores: { screen = .scores },
                    onSettings: { screen = .settings }
                )
            case .classicSetup:
                ClassicSetupView(
                    onStart: { difficulty in
                        screen = .classic(difficulty)
                    },
                    onBack: { screen = .menu }
                )
            case let .classic(difficulty):
                GameView(viewModel: GameViewModel(mode: .classic, level: difficulty)) {
                    screen = .menu
                }
                .id("classic-\(difficulty)")
            case .quickTour:
                GameView(viewModel: GameViewModel(mode: .quickTour)) {
                    screen = .menu
                }
                .id("quick-\(UUID().uuidString)")
            case .daily:
                GameView(viewModel: GameViewModel(mode: .daily)) {
                    screen = .menu
                }
                .id("daily-\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)")
            case .challengeSetup:
                ChallengeSetupView(
                    onStart: { difficulty in
                        screen = .challenge(difficulty)
                    },
                    onBack: { screen = .menu }
                )
            case let .challenge(difficulty):
                GameView(viewModel: GameViewModel(mode: .challenge, level: difficulty)) {
                    screen = .menu
                }
                .id("challenge-\(difficulty)")
            case .categorySelection:
                CategorySelectionView(
                    onSelect: { category, difficulty, questionCount in
                        screen = .categoryGame(category, difficulty, questionCount)
                    },
                    onBack: { screen = .menu }
                )
            case let .categoryGame(category, difficulty, questionCount):
                GameView(viewModel: GameViewModel(mode: .categoryChallenge, level: difficulty, category: category, questionCount: questionCount)) {
                    screen = .menu
                }
                .id("category-\(category)-\(difficulty)-\(questionCount)")
            case .privateChallengeSetup:
                PrivateChallengeSetupView(
                    onStart: { challenge in
                        screen = .privateChallengeGame(challenge)
                    },
                    onBack: { screen = .menu }
                )
            case let .privateChallengeGame(challenge):
                GameView(viewModel: GameViewModel(mode: .privateChallenge, privateChallenge: challenge)) {
                    screen = .menu
                }
                .id("private-\(challenge.id.uuidString)")
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
        .onOpenURL { url in
            let service = PrivateChallengeService()
            guard let challenge = service.challenge(from: url.absoluteString),
                  !service.hasJoined(challenge) else { return }
            service.markJoined(challenge)
            screen = .privateChallengeGame(challenge)
        }
    }
}

extension View {
    func swipeBackGesture(_ action: @escaping () -> Void) -> some View {
        highPriorityGesture(
            DragGesture(minimumDistance: 28, coordinateSpace: .local)
                .onEnded { value in
                    guard value.startLocation.x < 38,
                          value.translation.width > 80,
                          abs(value.translation.height) < 70 else { return }
                    action()
                }
        )
    }
}

private struct ClassicSetupView: View {
    let onStart: (Int) -> Void
    let onBack: () -> Void

    @State private var difficulty = 2

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                CloseButton(action: onBack)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Klasik Mod")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("16 soru, 180 saniye ve seçtiğin zorlukta kelime havuzu.")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.70))
                }

                Spacer()
            }

            DifficultyPicker(difficulty: $difficulty)

            VStack(spacing: 10) {
                InfoPill(title: "Soru", value: "16")
                InfoPill(title: "Süre", value: "180 sn")
                InfoPill(title: "Düzen", value: "Her uzunluktan 2 soru")
            }
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20))

            Button {
                onStart(difficulty)
            } label: {
                Label("Başla", systemImage: "play.fill")
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
        .swipeBackGesture(onBack)
    }
}

private struct ChallengeSetupView: View {
    let onStart: (Int) -> Void
    let onBack: () -> Void

    @State private var difficulty = 2

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                CloseButton(action: onBack)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Challenge Mod")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Zorluk arttıkça soru havuzu sertleşir, süre dengeli azalır.")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.70))
                }

                Spacer()
            }

            DifficultyPicker(difficulty: $difficulty)

            VStack(spacing: 10) {
                InfoPill(title: "Soru", value: "\(min(5 + difficulty, 8))")
                InfoPill(title: "Süre", value: "\(challengeDuration(for: difficulty)) sn")
                InfoPill(title: "Ödül", value: "Yıldız ve altın")
            }
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20))

            Button {
                onStart(difficulty)
            } label: {
                Label("Başla", systemImage: "play.fill")
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
        .swipeBackGesture(onBack)
    }
}

private func challengeDuration(for difficulty: Int) -> Int {
    max(120 - (min(max(difficulty, 1), 5) - 1) * 10, 80)
}

private struct CategorySelectionView: View {
    let onSelect: (String, Int, Int) -> Void
    let onBack: () -> Void

    @State private var categories: [(category: String, count: Int)] = []
    @State private var difficulty = 2
    @State private var questionCount = 8
    private let questionService = QuestionService()
    private let scoreService = ScoreService()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                CloseButton(action: onBack)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Kategori Haritası")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Kategorilerden bir ada seç, zorluk ve soru sayısıyla kendi bölümünü kur.")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.70))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            DifficultyPicker(difficulty: $difficulty)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Soru Sayısı", systemImage: "number.circle.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(questionCount)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                }

                Stepper(value: $questionCount, in: 5...15, step: 1) {
                    Text("En fazla 15 soru")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .tint(GameTheme.yellow)
            }
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(GameTheme.yellow)
                Text("\(min(scoreService.categoryMapUnlockedCount(), categories.count))/\(categories.count) ada açık")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                Text("10. adadan sonra daha çok yıldız ister")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(.horizontal, 22)

            ScrollView {
                ZStack(alignment: .top) {
                    MapPathView(count: categories.count)
                        .stroke(GameTheme.yellow.opacity(0.30), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [10, 10]))
                        .padding(.horizontal, 82)
                        .padding(.top, 44)
                        .allowsHitTesting(false)

                    LazyVStack(spacing: 14) {
                        ForEach(Array(categories.enumerated()), id: \.element.category) { index, item in
                            let isUnlocked = index < scoreService.categoryMapUnlockedCount()
                            let requiredStars = scoreService.requiredStarsForCategoryMapNode(at: index)
                            Button {
                                guard isUnlocked else { return }
                                onSelect(item.category, difficulty, min(questionCount, item.count))
                            } label: {
                                MapIslandCard(
                                    category: item.category,
                                    countText: "\(min(questionCount, item.count))/\(item.count) soru",
                                    icon: icon(for: item.category),
                                    index: index,
                                    isUnlocked: isUnlocked,
                                    requiredStars: requiredStars
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!isUnlocked)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            categories = questionService.categoryCounts()
        }
        .swipeBackGesture(onBack)
    }

    private func icon(for category: String) -> String {
        switch category {
        case "Bilim", "Fizik", "Kimya", "Biyoloji": return "atom"
        case "Dil", "Edebiyat": return "text.book.closed.fill"
        case "Tarih", "Kültür": return "building.columns.fill"
        case "Coğrafya", "Doğa": return "globe.europe.africa.fill"
        case "Teknoloji", "Teknik": return "cpu.fill"
        case "Spor": return "sportscourt.fill"
        case "Müzik", "Sanat": return "paintpalette.fill"
        case "Ekonomi": return "chart.line.uptrend.xyaxis"
        case "Hukuk": return "scale.3d"
        case "Tıp", "Psikoloji": return "cross.case.fill"
        default: return "tag.fill"
        }
    }
}

private struct MapIslandCard: View {
    let category: String
    let countText: String
    let icon: String
    let index: Int
    let isUnlocked: Bool
    let requiredStars: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(GameTheme.yellow)
                    .frame(width: 54, height: 54)
                    .shadow(color: GameTheme.yellow.opacity(0.35), radius: 12, y: 4)
                Image(systemName: icon)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(countText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.76))

                if requiredStars > 1 {
                    Label("\(requiredStars) yıldızla sıradaki ada açılır", systemImage: "star.fill")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                }
            }

            Spacer()

            Image(systemName: isUnlocked ? "play.fill" : "lock.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(GameTheme.yellow)
        }
        .padding(14)
        .frame(width: 250)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.50, green: 0.25, blue: 0.86).opacity(0.95),
                    Color(red: 0.23, green: 0.12, blue: 0.52).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(GameTheme.yellow.opacity(0.42), lineWidth: 1.8)
        )
        .shadow(color: .black.opacity(0.24), radius: 12, y: 7)
        .opacity(isUnlocked ? 1 : 0.54)
        .frame(maxWidth: .infinity, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
        .padding(.leading, index.isMultiple(of: 2) ? 4 : 0)
        .padding(.trailing, index.isMultiple(of: 2) ? 0 : 4)
    }
}

private struct MapPathView: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 1 else { return path }

        let step = max(rect.height / CGFloat(count), 78)
        path.move(to: CGPoint(x: rect.minX + 28, y: rect.minY + 30))

        for index in 1..<count {
            let y = rect.minY + 30 + CGFloat(index) * step
            let x = index.isMultiple(of: 2) ? rect.minX + 28 : rect.maxX - 28
            let previousX = index.isMultiple(of: 2) ? rect.maxX - 28 : rect.minX + 28
            path.addCurve(
                to: CGPoint(x: x, y: y),
                control1: CGPoint(x: previousX, y: y - step * 0.45),
                control2: CGPoint(x: x, y: y - step * 0.55)
            )
        }

        return path
    }
}

private struct DifficultyPicker: View {
    @Binding var difficulty: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Zorluk", systemImage: "slider.horizontal.3")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Spacer()

                Text(label)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(GameTheme.yellow)
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        difficulty = value
                    } label: {
                        Text("\(value)")
                            .font(.headline.weight(.black))
                            .foregroundStyle(difficulty == value ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                difficulty == value ? GameTheme.yellow : .white.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(GameTheme.yellow.opacity(0.22), lineWidth: 1)
        )
    }

    private var label: String {
        switch difficulty {
        case 1: return "Rahat"
        case 2: return "Normal"
        case 3: return "Dengeli"
        case 4: return "Zor"
        default: return "Usta"
        }
    }
}

private struct InfoPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.70))
            Spacer()
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
        }
    }
}

private struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
