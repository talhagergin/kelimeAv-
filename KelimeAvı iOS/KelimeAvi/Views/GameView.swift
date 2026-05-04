import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var scene = GameScene(size: CGSize(width: 360, height: 150))
    @State private var showJokers = false
    @State private var feedback: FeedbackState?
    @State private var showChallengeAdBreak = true
    let onExit: () -> Void

    init(viewModel: GameViewModel, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExit = onExit
    }

    var body: some View {
        if let result = viewModel.result {
            if viewModel.mode == .challenge, showChallengeAdBreak {
                ChallengeAdBreakView(
                    coinReward: viewModel.lastChallengeCoinReward,
                    onRewardedAd: viewModel.earnRewardedAdCoins,
                    onContinue: { showChallengeAdBreak = false }
                )
            } else {
                ResultView(result: result, onReplay: replay, onMenu: onExit)
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

                        LetterBoxesView(letters: viewModel.composedAnswerLetters, height: metrics.letterHeight)

                        TurkishKeyboardView(
                            letters: viewModel.keyboardLetters,
                            keyHeight: metrics.keyHeight,
                            onTap: viewModel.appendLetter,
                            onDelete: viewModel.deleteLastLetter
                        )

                        controls(height: metrics.controlHeight)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.topPadding)
                    .padding(.bottom, metrics.bottomPadding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                    if showJokers {
                        jokerOverlay
                            .padding(.horizontal, metrics.horizontalPadding)
                    }

                    if let feedback {
                        FeedbackBanner(state: feedback)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .onChange(of: viewModel.animationEvent) { _, event in
                handleAnimation(event)
            }
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
                    .fill(.black.opacity(0.22))
                    .frame(height: 120)
            }
            .ignoresSafeArea()
        }
    }

    private func header(height: CGFloat) -> some View {
        HStack(spacing: 9) {
            Button(action: onExit) {
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
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)

            if let challengeTitle = viewModel.challengeTitle {
                Text(challengeTitle)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
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

            if viewModel.mode == .challenge {
                ActionButton(title: "Jokerler", icon: "wand.and.stars", color: GameTheme.orange, height: height) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        showJokers.toggle()
                    }
                }
            } else if viewModel.mode == .classic {
                ActionButton(title: "İpucu", icon: "lightbulb.fill", color: GameTheme.orange, height: height) {
                    viewModel.extendClassicClue()
                }
                .disabled(!viewModel.canExtendClassicClue)
                .opacity(viewModel.canExtendClassicClue ? 1 : 0.42)
            }
        }
    }

    private var jokerOverlay: some View {
        VStack {
            Spacer()

            JokerBarView(viewModel: viewModel) {
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
            .padding(.bottom, 78)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var answerButtonTitle: String {
        if (viewModel.mode == .classic || viewModel.mode == .privateChallenge), viewModel.isAnswerWindowActive {
            return "Cevapla \(viewModel.answerWindowRemaining)"
        }
        return (viewModel.mode == .classic || viewModel.mode == .privateChallenge) ? "Süreyi Durdur" : "Cevapla"
    }

    private var timeText: String {
        let seconds = viewModel.isAnswerWindowActive ? viewModel.answerWindowRemaining : viewModel.timeRemaining
        return "\(seconds)"
    }

    private func resizeScene(width: CGFloat, height: CGFloat) {
        scene.size = CGSize(width: max(width, 280), height: height)
        scene.configure(wordLength: viewModel.currentQuestion?.letterCount ?? 0)
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
        case .insufficientCoins:
            showFeedback(.insufficientCoins)
        case let .lowTime(active):
            scene.setLowTime(active)
        case let .joker(joker):
            scene.playJoker(joker)
        case let .reset(wordLength):
            scene.configure(wordLength: wordLength)
            scene.setLowTime(false)
            showJokers = false
        }
    }

    private func replay() {
        showChallengeAdBreak = true
        feedback = nil
        viewModel.start()
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

private struct GameLayoutMetrics {
    let size: CGSize

    var isCompactHeight: Bool { size.height < 780 }
    var horizontalPadding: CGFloat { 14 }
    var topPadding: CGFloat { isCompactHeight ? 8 : 14 }
    var bottomPadding: CGFloat { isCompactHeight ? 8 : 12 }
    var spacing: CGFloat { isCompactHeight ? 8 : 10 }
    var headerHeight: CGFloat { isCompactHeight ? 50 : 56 }
    var clueHeight: CGFloat { isCompactHeight ? 98 : 108 }
    var sceneHeight: CGFloat { isCompactHeight ? 128 : 150 }
    var letterHeight: CGFloat { isCompactHeight ? 36 : 42 }
    var keyHeight: CGFloat { isCompactHeight ? 33 : 37 }
    var controlHeight: CGFloat { isCompactHeight ? 54 : 58 }
}

private enum FeedbackState: Equatable {
    case correct(points: Int)
    case wrong(answer: String)
    case timeout(answer: String)
    case insufficientCoins

    var title: String {
        switch self {
        case .correct: "DOĞRU!"
        case .wrong: "YANLIŞ"
        case .timeout: "SÜRE DOLDU"
        case .insufficientCoins: "YETERSİZ ALTIN"
        }
    }

    var subtitle: String {
        switch self {
        case let .correct(points): "+\(points) puan"
        case let .wrong(answer): "Cevap: \(answer)"
        case .timeout: "+0 puan"
        case .insufficientCoins: "Reklam izleyerek altın kazan"
        }
    }

    var color: Color {
        switch self {
        case .correct: .green
        case .wrong: .red
        case .timeout: GameTheme.orange
        case .insufficientCoins: GameTheme.orange
        }
    }

    var icon: String {
        switch self {
        case .correct: "checkmark.seal.fill"
        case .wrong: "xmark.octagon.fill"
        case .timeout: "timer"
        case .insufficientCoins: "bitcoinsign.circle.fill"
        }
    }
}

private struct FeedbackBanner: View {
    let state: FeedbackState

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: state.icon)
                .font(.system(size: 46, weight: .black))
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
