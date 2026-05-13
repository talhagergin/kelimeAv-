import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var scene = GameScene(size: CGSize(width: 360, height: 150))
    @State private var showJokers = false
    @State private var feedback: FeedbackState?
    @State private var showChallengeAdBreak = true
    @State private var showSoftAdBreak = false
    @State private var didEvaluateSoftAdBreak = false
    @State private var showPrivateCompletionAd = true
    @State private var showAttemptInterstitial = false
    @State private var didRegisterGameAttempt = false
    @State private var showDailyExitWarning = false
    @State private var isBannerLoaded = false
    let onExit: () -> Void

    init(viewModel: GameViewModel, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            content

            if showAttemptInterstitial {
                AutoInterstitialView(message: "Kısa bir reklam hazırlanıyor") {
                    showAttemptInterstitial = false
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            registerGameAttemptIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let result = viewModel.result {
            if viewModel.mode == .privateChallenge, showPrivateCompletionAd {
                AutoInterstitialView(message: "Meydan okuma tamamlandı") {
                    showPrivateCompletionAd = false
                }
            } else if viewModel.usesChallengeRules, showChallengeAdBreak {
                ChallengeAdBreakView(
                    coinReward: viewModel.lastChallengeCoinReward,
                    onRewardedAd: viewModel.grantRewardedAdCoins,
                    onContinue: { showChallengeAdBreak = false }
                )
            } else if showSoftAdBreak {
                SoftAdBreakView {
                    showSoftAdBreak = false
                }
            } else {
                ResultView(result: result, onReplay: replay, onMenu: onExit)
                    .onAppear {
                        evaluateSoftAdBreak()
                    }
            }
        } else {
            GeometryReader { proxy in
                let metrics = GameLayoutMetrics(size: proxy.size)

                ZStack {
                    decorativeLayer

                    VStack(spacing: metrics.spacing) {
                        header(height: metrics.headerHeight)
                        cluePanel(height: metrics.clueHeight)

                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .frame(height: metrics.sceneHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(GameTheme.yellow.opacity(0.28), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
                            .onAppear {
                                resizeScene(width: proxy.size.width - metrics.horizontalPadding * 2, height: metrics.sceneHeight)
                            }
                            .onChange(of: proxy.size) { _, newSize in
                                resizeScene(width: newSize.width - metrics.horizontalPadding * 2, height: metrics.sceneHeight)
                            }
                            .onChange(of: viewModel.currentQuestion?.id) { _, _ in
                                resetScene(width: proxy.size.width - metrics.horizontalPadding * 2, height: metrics.sceneHeight)
                            }

                        LetterBoxesView(
                            letters: viewModel.composedAnswerLetters,
                            selectedIndex: viewModel.selectedAnswerIndex,
                            height: metrics.letterHeight,
                            skin: viewModel.tileSkin,
                            onTap: viewModel.selectAnswerSlot
                        )

                        TurkishKeyboardView(
                            letters: viewModel.keyboardLetters,
                            keyHeight: metrics.keyHeight,
                            skin: viewModel.tileSkin,
                            onTap: viewModel.appendLetter,
                            onDelete: viewModel.deleteLastLetter
                        )

                        footer(metrics: metrics)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.topPadding)
                    .padding(.bottom, metrics.bottomPadding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                    if showJokers {
                        jokerOverlay(metrics: metrics)
                            .padding(.horizontal, metrics.horizontalPadding)
                    }

                    if let feedback {
                        FeedbackBanner(state: feedback)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if showDailyExitWarning {
                        DailyExitWarningView(
                            onCancel: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    showDailyExitWarning = false
                                }
                            },
                            onConfirm: {
                                viewModel.abandonDailyRun()
                                onExit()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    if viewModel.isMainTimerCritical {
                        CriticalTimerFrame()
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                }
            }
            .onChange(of: viewModel.animationEvent) { _, event in
                handleAnimation(event)
            }
            .swipeBackGesture(exitButtonTapped)
        }
    }

    private var decorativeLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.50, green: 0.20, blue: 0.82).opacity(0.32),
                    Color(red: 0.18, green: 0.08, blue: 0.40).opacity(0.10),
                    GameTheme.orange.opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.18), .black.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 92)
            }
            .ignoresSafeArea()
        }
    }

    private func header(height: CGFloat) -> some View {
        HStack(spacing: 9) {
            Button(action: exitButtonTapped) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: height, height: height)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            StatCapsule(title: "Süre", value: timeText, tint: viewModel.isTimeFrozen ? .cyan : GameTheme.yellow)
            StatCapsule(title: "Skor", value: "\(viewModel.score)", tint: .white)
            StatCapsule(title: "Soru", value: viewModel.questionNumberText, tint: GameTheme.orange)
        }
        .frame(height: height)
    }

    private func exitButtonTapped() {
        if viewModel.mode == .daily, viewModel.result == nil {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showDailyExitWarning = true
            }
        } else {
            onExit()
        }
    }

    private func cluePanel(height: CGFloat) -> some View {
        VStack(spacing: 6) {
            HStack {
                Label(viewModel.currentQuestion?.category ?? "Kategori", systemImage: "tag.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(GameTheme.yellow)
                Spacer()
                Text("\(viewModel.currentPotentialScore) puan")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }

            Text(viewModel.clueText)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.50)
                .frame(maxWidth: .infinity)

            if let extendedClue = viewModel.extendedClueText {
                Text(extendedClue)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(GameTheme.yellow)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.14), in: Capsule())
            }

            if let challengeTitle = viewModel.challengeTitle {
                Text(challengeTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
            }

            if viewModel.comboText != nil {
                HStack(spacing: 8) {
                    if let comboText = viewModel.comboText {
                        ClueStatusPill(text: comboText, icon: "bolt.fill", color: GameTheme.yellow)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.20), .white.opacity(0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 7)
    }

    private func controls(height: CGFloat) -> some View {
        HStack(spacing: 10) {
            ActionButton(title: "Harf Aç", icon: "sparkles", color: GameTheme.yellow, height: height) {
                viewModel.revealLetter()
            }
            .disabled(!viewModel.canRevealLetter)
            .opacity(viewModel.canRevealLetter ? 1 : 0.42)

            ActionButton(title: answerButtonTitle, icon: "checkmark.circle.fill", color: GameTheme.blue, height: height) {
                viewModel.answerButtonTapped()
            }

            if viewModel.usesChallengeRules {
                ActionButton(title: "Jokerler", icon: "wand.and.stars", color: GameTheme.orange, height: height) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        showJokers.toggle()
                    }
                }
            } else if viewModel.mode == .classic {
                ActionButton(title: "İpucu \(viewModel.inventoryCount(for: .extendClue))", icon: "lightbulb.fill", color: GameTheme.orange, height: height) {
                    viewModel.extendClassicClue()
                }
                .disabled(!viewModel.canExtendClassicClue)
                .opacity(viewModel.canExtendClassicClue ? 1 : 0.42)
            } else if viewModel.mode == .privateChallenge {
                ActionButton(title: "Pas \(viewModel.remainingPasses)", icon: "forward.fill", color: GameTheme.orange, height: height) {
                    viewModel.passQuestion()
                }
                .disabled(!viewModel.canPassQuestion)
                .opacity(viewModel.canPassQuestion ? 1 : 0.42)
            }
        }
    }

    private func footer(metrics: GameLayoutMetrics) -> some View {
        VStack(spacing: metrics.footerSpacing) {
            controls(height: metrics.controlHeight)

            AdBannerView(isLoaded: $isBannerLoaded)
                .frame(height: isBannerLoaded ? metrics.adHeight : 1)
                .frame(maxWidth: .infinity)
                .background(isBannerLoaded ? .white.opacity(0.96) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isBannerLoaded ? .white.opacity(0.45) : .clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(isBannerLoaded ? 1 : 0)
        }
        .padding(.top, 2)
    }

    private func jokerOverlay(metrics: GameLayoutMetrics) -> some View {
        VStack {
            Spacer()

            JokerBarView(viewModel: viewModel) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showJokers = false
                }
            } onClose: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showJokers = false
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(GameTheme.yellow.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 18, y: 10)
            .padding(.bottom, metrics.jokerOverlayBottomPadding)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var answerButtonTitle: String {
        if viewModel.isAnswerWindowActive {
            return "Cevapla \(viewModel.answerWindowRemaining)"
        }
        return "Süreyi Durdur"
    }

    private var timeText: String {
        let seconds = viewModel.isAnswerWindowActive ? viewModel.answerWindowRemaining : viewModel.timeRemaining
        return "\(seconds)"
    }

    private func resizeScene(width: CGFloat, height: CGFloat) {
        scene.size = CGSize(width: max(width, 280), height: height)
        scene.configure(wordLength: viewModel.currentQuestion?.letterCount ?? 0, skin: viewModel.tileSkin)
    }

    private func resetScene(width: CGFloat, height: CGFloat) {
        scene.size = CGSize(width: max(width, 280), height: height)
        scene.configure(wordLength: viewModel.currentQuestion?.letterCount ?? 0, skin: viewModel.tileSkin)
        scene.applySkin(viewModel.tileSkin)
        scene.setLowTime(false)
        showJokers = false
    }

    private func handleAnimation(_ event: GameAnimationEvent?) {
        guard let event else { return }
        switch event {
        case let .reveal(index, letter):
            scene.revealLetter(at: index, letter: letter)
        case let .correct(word, points):
            scene.revealWord(word, points: points)
            showFeedback(.correct(points: points))
        case let .wrong(word):
            scene.revealWrongWord(word)
            showFeedback(.wrong(answer: word))
        case let .timeout(word):
            scene.revealWrongWord(word)
            showFeedback(.timeout(answer: word))
        case let .failed(word, penalty):
            scene.revealWrongWord(word)
            showFeedback(.failed(penalty: penalty))
        case .insufficientCoins:
            showFeedback(.insufficientCoins)
        case let .lowTime(active):
            scene.setLowTime(active)
        case let .joker(joker):
            scene.playJoker(joker)
        case let .reset(wordLength, _):
            scene.configure(wordLength: wordLength)
            scene.setLowTime(false)
            showJokers = false
        }
    }

    private func replay() {
        showChallengeAdBreak = true
        showPrivateCompletionAd = true
        showSoftAdBreak = false
        didEvaluateSoftAdBreak = false
        didRegisterGameAttempt = false
        feedback = nil
        viewModel.start()
        registerGameAttemptIfNeeded()
    }

    private func evaluateSoftAdBreak() {
        guard !didEvaluateSoftAdBreak else { return }
        didEvaluateSoftAdBreak = true
        guard !viewModel.usesChallengeRules else { return }
        guard viewModel.mode != .privateChallenge else { return }
        showSoftAdBreak = AdPlacementPolicy.shared.shouldOfferSoftAdBreak()
    }

    private func registerGameAttemptIfNeeded() {
        guard !didRegisterGameAttempt else { return }
        didRegisterGameAttempt = true
        guard AdPlacementPolicy.shared.shouldShowInterstitialAfterGameAttempt() else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showAttemptInterstitial = true
        }
    }

    private func showFeedback(_ state: FeedbackState) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            feedback = state
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeOut(duration: 0.2)) {
                feedback = nil
            }
        }
    }
}

private struct AutoInterstitialView: View {
    let message: String
    let onFinished: () -> Void
    @State private var didStart = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(GameTheme.yellow)
                    .scaleEffect(1.2)

                Text(message)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Text("Birazdan devam edeceksin")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(22)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(GameTheme.yellow.opacity(0.22), lineWidth: 1)
            )
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            AdService.shared.showInterstitialAd(onFinished: onFinished)
        }
    }
}

private struct DailyExitWarningView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.50)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(GameTheme.orange.opacity(0.20))
                        .frame(width: 72, height: 72)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(GameTheme.yellow)
                }

                Text("Günlük hakkın bitecek")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Şimdi çıkarsan bugünkü Günlük Kelime Avı tekrar açılmaz ve günlük serin sıfırlanır.")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Devam Et")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    Button(action: onConfirm) {
                        Text("Çık")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(
                LinearGradient(
                    colors: [GameTheme.panel.opacity(0.98), Color(red: 0.36, green: 0.12, blue: 0.58).opacity(0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(GameTheme.yellow.opacity(0.26), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.40), radius: 28, y: 16)
            .padding(.horizontal, 24)
        }
    }
}

private struct CriticalTimerFrame: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.45)) { context in
            let pulse = Int(context.date.timeIntervalSince1970 * 2) % 2 == 0
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    Color.red.opacity(pulse ? 0.95 : 0.25),
                    style: StrokeStyle(lineWidth: pulse ? 5 : 2)
                )
                .shadow(color: .red.opacity(pulse ? 0.72 : 0.12), radius: pulse ? 18 : 4)
                .padding(7)
                .animation(.easeInOut(duration: 0.22), value: pulse)
        }
        .ignoresSafeArea()
    }
}

private struct ClueStatusPill: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.18), in: Capsule())
    }
}

private struct GameLayoutMetrics {
    let size: CGSize

    var isCompactHeight: Bool { size.height < 780 }
    var horizontalPadding: CGFloat { 14 }
    var topPadding: CGFloat { isCompactHeight ? 8 : 14 }
    var bottomPadding: CGFloat { isCompactHeight ? 7 : 10 }
    var spacing: CGFloat { isCompactHeight ? 8 : 10 }
    var headerHeight: CGFloat { isCompactHeight ? 50 : 56 }
    var clueHeight: CGFloat { isCompactHeight ? 112 : 128 }
    var sceneHeight: CGFloat { isCompactHeight ? 108 : 128 }
    var letterHeight: CGFloat { isCompactHeight ? 40 : 46 }
    var keyHeight: CGFloat { isCompactHeight ? 43 : 48 }
    var controlHeight: CGFloat { isCompactHeight ? 50 : 54 }
    var adHeight: CGFloat { 50 }
    var footerSpacing: CGFloat { isCompactHeight ? 10 : 12 }
    var jokerOverlayBottomPadding: CGFloat {
        adHeight + (isCompactHeight ? 12 : 16)
    }
}

private enum FeedbackState: Equatable {
    case correct(points: Int)
    case wrong(answer: String)
    case timeout(answer: String)
    case failed(penalty: Int)
    case insufficientCoins

    var title: String {
        switch self {
        case .correct: "DOĞRU!"
        case .wrong: "YANLIŞ"
        case .timeout: "SÜRE DOLDU"
        case .failed: "CEVAPLANAMADI"
        case .insufficientCoins: "YETERSİZ ALTIN"
        }
    }

    var subtitle: String {
        switch self {
        case let .correct(points): "+\(points) puan"
        case let .wrong(answer): "Cevap: \(answer)"
        case .timeout: "+0 puan"
        case let .failed(penalty): "-\(penalty) puan"
        case .insufficientCoins: "Reklam izleyerek altın kazan"
        }
    }

    var color: Color {
        switch self {
        case .correct: .green
        case .wrong: .red
        case .timeout: GameTheme.orange
        case .failed: .red
        case .insufficientCoins: GameTheme.orange
        }
    }

    var icon: String {
        switch self {
        case .correct: "checkmark.seal.fill"
        case .wrong: "xmark.octagon.fill"
        case .timeout: "timer"
        case .failed: "minus.circle.fill"
        case .insufficientCoins: "circle.fill"
        }
    }
}

private struct FeedbackBanner: View {
    let state: FeedbackState

    var body: some View {
        VStack(spacing: 8) {
            if state == .insufficientCoins {
                CoinIcon(size: 52)
            } else {
                Image(systemName: state.icon)
                    .font(.system(size: 46, weight: .black))
            }
            Text(state.title)
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text(state.subtitle)
                .font(.headline.weight(.black))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 22)
        .background(state.color.opacity(0.92), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.28), lineWidth: 2)
        )
        .shadow(color: state.color.opacity(0.45), radius: 24, y: 10)
    }
}

private struct StatCapsule: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.28), .black.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.headline.weight(.black))
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .font(.subheadline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.98), color.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.25), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}
