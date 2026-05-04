import Combine
import Foundation

enum GameAnimationEvent: Equatable {
    case reveal(index: Int, letter: String)
    case correct(word: String, points: Int)
    case wrong(word: String)
    case timeout(word: String)
    case insufficientCoins
    case lowTime(Bool)
    case joker(JokerType)
    case reset(wordLength: Int)
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var mode: GameMode
    @Published private(set) var level: Int
    @Published private(set) var questions: [WordQuestion] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var openedIndices: Set<Int> = []
    @Published private(set) var score: Int = 0
    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var answerWindowRemaining: Int = 0
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var wrongCount: Int = 0
    @Published private(set) var revealedLetterCount: Int = 0
    @Published private(set) var usedJokers: Set<JokerType> = []
    @Published private(set) var removedKeyboardLetters: Set<String> = []
    @Published private(set) var isTimeFrozen: Bool = false
    @Published private(set) var isShowingExtendedClue: Bool = false
    @Published private(set) var coins: Int = 0
    @Published private(set) var coinMessage: String?
    @Published private(set) var lastChallengeCoinReward: Int = 0
    @Published private(set) var result: GameResult?
    @Published var answerText: String = ""
    @Published var animationEvent: GameAnimationEvent?

    private let questionService: QuestionProviding
    private let scoreService: ScoreStoring
    private let soundService: SoundPlaying
    private let privateChallenge: PrivateChallenge?
    private var timerTask: Task<Void, Never>?
    private var answerTimerTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var freezeTask: Task<Void, Never>?
    private var questionRevision = UUID()
    private var hasPlayedTension = false

    init(
        mode: GameMode,
        level: Int = 1,
        privateChallenge: PrivateChallenge? = nil,
        questionService: QuestionProviding? = nil,
        scoreService: ScoreStoring? = nil,
        soundService: SoundPlaying? = nil
    ) {
        self.mode = mode
        self.level = level
        self.privateChallenge = privateChallenge
        self.questionService = questionService ?? QuestionService()
        self.scoreService = scoreService ?? ScoreService()
        self.soundService = soundService ?? SoundService()
        start()
    }

    deinit {
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()
    }

    var jokerCost: Int { 12 }

    var currentQuestion: WordQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var questionNumberText: String {
        "\(min(currentIndex + 1, questions.count))/\(questions.count)"
    }

    var currentPotentialScore: Int {
        max(0, (currentQuestion?.letterCount ?? 0) * 100 - openedIndices.count * 100)
    }

    var visibleLetters: [String?] {
        guard let question = currentQuestion else { return [] }
        return question.answer.turkishLetters.enumerated().map { index, letter in
            openedIndices.contains(index) ? letter : nil
        }
    }

    var composedAnswerLetters: [String?] {
        guard let question = currentQuestion else { return [] }
        let typedLetters = answerText.turkishLetters
        var typedIndex = 0

        return question.answer.turkishLetters.indices.map { index in
            if openedIndices.contains(index) {
                return question.answer.turkishLetters[index]
            }

            defer { typedIndex += typedIndex < typedLetters.count ? 1 : 0 }
            return typedLetters.indices.contains(typedIndex) ? typedLetters[typedIndex] : nil
        }
    }

    var composedAnswerText: String {
        composedAnswerLetters.compactMap { $0 }.joined()
    }

    var clueText: String {
        guard let question = currentQuestion else { return "" }
        return isShowingExtendedClue ? question.extendedClue : question.clue
    }

    var keyboardLetters: [String] {
        TurkishAlphabet.qKeyboardRows.flatMap { $0 }.filter { !removedKeyboardLetters.contains($0) }
    }

    var isAnswerWindowActive: Bool {
        answerWindowRemaining > 0
    }

    var canRevealLetter: Bool {
        result == nil && hasHiddenLetter && !(requiresAnswerWindow && isAnswerWindowActive)
    }

    var canExtendClassicClue: Bool {
        mode == .classic && !isShowingExtendedClue && result == nil
    }

    var challengeTitle: String? {
        privateChallenge?.title
    }

    func start() {
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()
        answerWindowRemaining = 0
        answerText = ""
        animationEvent = nil
        isTimeFrozen = false
        if let privateChallenge {
            let sharedQuestions = questionService.questions(matching: privateChallenge.questionIDs)
            questions = sharedQuestions.isEmpty
                ? questionService.privateChallengeQuestions(count: privateChallenge.questionIDs.count, maxDifficulty: privateChallenge.maxDifficulty)
                : sharedQuestions
        } else {
            questions = mode == .classic
                ? questionService.classicQuestions()
                : questionService.challengeQuestions(level: level)
        }
        currentIndex = 0
        score = 0
        coins = scoreService.coins
        coinMessage = nil
        lastChallengeCoinReward = 0
        correctCount = 0
        wrongCount = 0
        revealedLetterCount = 0
        usedJokers = []
        result = nil
        timeRemaining = privateChallenge?.totalTime ?? (mode == .classic ? 240 : max(70 - (level - 1) * 8, 35))
        prepareCurrentQuestion()
        startMainTimer()
    }

    func appendLetter(_ letter: String) {
        guard result == nil else { return }
        if requiresAnswerWindow, !isAnswerWindowActive {
            startAnswerWindow()
        }
        let maxLength = maxHiddenLetterCount
        guard answerText.count < maxLength else { return }
        answerText += letter
    }

    func deleteLastLetter() {
        guard !answerText.isEmpty else { return }
        answerText.removeLast()
    }

    func answerButtonTapped() {
        if requiresAnswerWindow, !isAnswerWindowActive {
            startAnswerWindow()
        } else {
            submitAnswer()
        }
    }

    func extendClassicClue() {
        guard canExtendClassicClue else { return }
        isShowingExtendedClue = true
        soundService.playJoker()
        animationEvent = .joker(.extendClue)
    }

    func submitAnswer() {
        guard let question = currentQuestion, result == nil else { return }
        guard !requiresAnswerWindow || isAnswerWindowActive else { return }

        if composedAnswerText.turkishGameNormalized() == question.answer.turkishGameNormalized() {
            let earnedPoints = currentPotentialScore
            score += earnedPoints
            correctCount += 1
            soundService.playCorrect()
            soundService.playWordReveal()
            openedIndices = Set(question.answer.turkishLetters.indices)
            answerText = ""
            animationEvent = .correct(word: question.answer, points: earnedPoints)
            moveToNextQuestionAfterDelay(seconds: 1.25)
        } else {
            wrongCount += 1
            soundService.playWrong()
            openedIndices = Set(question.answer.turkishLetters.indices)
            answerText = ""
            animationEvent = .wrong(word: question.answer)
            moveToNextQuestionAfterDelay(seconds: 1.65)
        }
    }

    func revealLetter() {
        guard canRevealLetter else { return }
        guard let question = currentQuestion else { return }
        let hidden = question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }
        guard let index = hidden.randomElement() else { return }
        openLetter(at: index, countsAsReveal: true)
    }

    func useJoker(_ joker: JokerType) {
        guard mode == .challenge, !usedJokers.contains(joker), result == nil else { return }
        guard scoreService.spendCoins(jokerCost) else {
            coinMessage = "Yetersiz altın. Reklam izleyerek +6 altın kazanabilirsin."
            soundService.playInsufficientCoins()
            animationEvent = .insufficientCoins
            return
        }
        coins = scoreService.coins

        switch joker {
        case .revealLetter:
            guard hasHiddenLetter else {
                refundJokerCost()
                return
            }
            revealLetter()
        case .firstLetter:
            guard !openedIndices.contains(0) else {
                refundJokerCost()
                return
            }
            openLetter(at: 0, countsAsReveal: true)
        case .removeWrongLetters:
            removeWrongKeyboardLetters()
        case .freezeTime:
            freezeTime()
        case .extendClue:
            isShowingExtendedClue = true
        }

        usedJokers.insert(joker)
        soundService.playJoker()
        animationEvent = .joker(joker)
    }

    func clearCoinMessage() {
        coinMessage = nil
    }

    func earnRewardedAdCoins() {
        scoreService.addCoins(6)
        coins = scoreService.coins
        coinMessage = "Reklam ödülü: +6 altın"
    }

    func isJokerEnabled(_ joker: JokerType) -> Bool {
        guard mode == .challenge, !usedJokers.contains(joker) else { return false }
        switch joker {
        case .revealLetter: return hasHiddenLetter
        case .firstLetter: return !openedIndices.contains(0)
        case .removeWrongLetters: return removedKeyboardLetters.isEmpty
        case .freezeTime: return !isTimeFrozen
        case .extendClue: return !isShowingExtendedClue
        }
    }

    private var hasHiddenLetter: Bool {
        guard let question = currentQuestion else { return false }
        return openedIndices.count < question.letterCount
    }

    private var requiresAnswerWindow: Bool {
        mode == .classic || mode == .privateChallenge
    }

    private var maxHiddenLetterCount: Int {
        guard let question = currentQuestion else { return 0 }
        return question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }.count
    }

    private func refundJokerCost() {
        scoreService.addCoins(jokerCost)
        coins = scoreService.coins
    }

    private func openLetter(at index: Int, countsAsReveal: Bool) {
        guard let question = currentQuestion, question.answer.turkishLetters.indices.contains(index) else { return }
        openedIndices.insert(index)
        if countsAsReveal {
            revealedLetterCount += 1
        }
        answerText = String(answerText.turkishLetters.prefix(maxHiddenLetterCount).joined())
        soundService.playLetterReveal()
        animationEvent = .reveal(index: index, letter: question.answer.turkishLetters[index])
    }

    private func removeWrongKeyboardLetters() {
        guard let question = currentQuestion else { return }
        let answerLetters = Set(question.answer.turkishLetters)
        let removable = TurkishAlphabet.qKeyboardRows.flatMap { $0 }.filter { !answerLetters.contains($0) }.shuffled()
        removedKeyboardLetters = Set(removable.prefix(8))
    }

    private func freezeTime() {
        isTimeFrozen = true
        freezeTask?.cancel()
        freezeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            await MainActor.run {
                self?.isTimeFrozen = false
            }
        }
    }

    private func startMainTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self?.tickMainTimer()
                }
            }
        }
    }

    private func tickMainTimer() {
        guard result == nil, !isTimeFrozen, !isAnswerWindowActive else { return }
        timeRemaining = max(0, timeRemaining - 1)
        animationEvent = .lowTime(timeRemaining <= 10)

        if timeRemaining == 5, !hasPlayedTension {
            hasPlayedTension = true
            soundService.playTension()
        }

        if timeRemaining == 0 {
            finishGame()
        }
    }

    private func startAnswerWindow() {
        guard result == nil else { return }
        let revision = questionRevision
        answerWindowRemaining = 10
        soundService.playTension()
        answerTimerTask?.cancel()
        answerTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self?.tickAnswerWindow(revision: revision)
                }
            }
        }
    }

    private func tickAnswerWindow(revision: UUID) {
        guard questionRevision == revision, answerWindowRemaining > 0 else { return }
        answerWindowRemaining -= 1

        if answerWindowRemaining <= 10 && answerWindowRemaining > 0 {
            soundService.playTick()
        }

        if answerWindowRemaining == 10 {
            soundService.playTension()
        }

        if answerWindowRemaining == 0 {
            expireAnswerWindow()
        }
    }

    private func expireAnswerWindow() {
        guard let question = currentQuestion, result == nil else { return }
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        wrongCount += 1
        soundService.playWrong()
        openedIndices = Set(question.answer.turkishLetters.indices)
        answerText = ""
        animationEvent = .timeout(word: question.answer)
        moveToNextQuestionAfterDelay(seconds: 1.65)
    }

    private func moveToNextQuestionAfterDelay(seconds: Double) {
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        let revision = questionRevision
        advanceTask?.cancel()
        advanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            await MainActor.run {
                guard self?.questionRevision == revision else { return }
                self?.advanceQuestion()
            }
        }
    }

    private func advanceQuestion() {
        if currentIndex + 1 >= questions.count {
            finishGame()
        } else {
            currentIndex += 1
            prepareCurrentQuestion()
        }
    }

    private func prepareCurrentQuestion() {
        questionRevision = UUID()
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        openedIndices = []
        answerText = ""
        removedKeyboardLetters = []
        isTimeFrozen = false
        isShowingExtendedClue = false
        hasPlayedTension = false
        coinMessage = nil
        animationEvent = .reset(wordLength: currentQuestion?.letterCount ?? 0)
    }

    private func finishGame() {
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()

        let stars = mode == .challenge ? calculateStars() : 0
        lastChallengeCoinReward = mode == .challenge ? calculateCoinReward(stars: stars) : 0
        if lastChallengeCoinReward > 0 {
            scoreService.addCoins(lastChallengeCoinReward)
            coins = scoreService.coins
        }
        let finalResult = GameResult(
            mode: mode,
            score: score,
            correctCount: correctCount,
            wrongCount: wrongCount,
            revealedLetterCount: revealedLetterCount,
            stars: stars
        )

        if mode == .classic {
            scoreService.saveClassicScore(score)
        } else if mode == .challenge {
            scoreService.saveStars(stars, forLevel: level)
        }

        result = finalResult
    }

    private func calculateStars() -> Int {
        let accuracy = questions.isEmpty ? 0 : Double(correctCount) / Double(questions.count)
        if accuracy >= 0.9 && revealedLetterCount <= 2 && timeRemaining >= 15 { return 3 }
        if accuracy >= 0.7 && revealedLetterCount <= 5 { return 2 }
        return correctCount > 0 ? 1 : 0
    }

    private func calculateCoinReward(stars: Int) -> Int {
        guard mode == .challenge else { return 0 }
        switch stars {
        case 3: return 5
        case 2: return 3
        case 1: return 1
        default: return 0
        }
    }
}

enum TurkishAlphabet {
    static let qKeyboardRows = [
        ["E", "R", "T", "Y", "U", "I", "O", "P", "Ğ", "Ü"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ş", "İ"],
        ["Z", "C", "V", "B", "N", "M", "Ö", "Ç"]
    ]

    static var letters: [String] {
        qKeyboardRows.flatMap { $0 }
    }
}
