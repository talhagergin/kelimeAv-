import Combine
import Foundation

enum GameAnimationEvent: Equatable {
    case reveal(index: Int, letter: String)
    case correct(word: String, points: Int)
    case wrong(word: String)
    case timeout(word: String)
    case failed(word: String, penalty: Int)
    case insufficientCoins
    case lowTime(Bool)
    case joker(JokerType)
    case reset(wordLength: Int, id: UUID)
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
    @Published private(set) var isRevealingLetter: Bool = false
    @Published private(set) var isShowingExtendedClue: Bool = false
    @Published private(set) var coins: Int = 0
    @Published private(set) var jokerInventory: [JokerType: Int] = [:]
    @Published private(set) var coinMessage: String?
    @Published private(set) var lastChallengeCoinReward: Int = 0
    @Published private(set) var comboStreak: Int = 0
    @Published private(set) var maxCombo: Int = 0
    @Published private(set) var tileSkin: TileSkin = .classicBlue
    @Published private(set) var remainingPasses: Int = 0
    @Published private(set) var result: GameResult?
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private var enteredAnswerLetters: [Int: String] = [:]
    @Published var answerText: String = ""
    @Published var animationEvent: GameAnimationEvent?

    private let questionService: QuestionProviding
    private let scoreService: ScoreStoring
    private let soundService: SoundPlaying
    private let privateChallenge: PrivateChallenge?
    private let selectedCategory: String?
    private let requestedQuestionCount: Int?
    private var timerTask: Task<Void, Never>?
    private var answerTimerTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var freezeTask: Task<Void, Never>?
    private var autoFailTask: Task<Void, Never>?
    private var revealCooldownTask: Task<Void, Never>?
    private var questionRevision = UUID()
    private var hasPlayedMainTension = false
    private var fastestCorrectThisRun: Int?

    init(
        mode: GameMode,
        level: Int = 1,
        category: String? = nil,
        questionCount: Int? = nil,
        privateChallenge: PrivateChallenge? = nil,
        questionService: QuestionProviding? = nil,
        scoreService: ScoreStoring? = nil,
        soundService: SoundPlaying? = nil
    ) {
        self.mode = mode
        self.level = level
        self.privateChallenge = privateChallenge
        self.selectedCategory = category
        self.requestedQuestionCount = questionCount
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
        autoFailTask?.cancel()
        revealCooldownTask?.cancel()
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

        return question.answer.turkishLetters.indices.map { index in
            if openedIndices.contains(index) {
                return question.answer.turkishLetters[index]
            }

            return enteredAnswerLetters[index]
        }
    }

    var composedAnswerText: String {
        composedAnswerLetters.compactMap { $0 }.joined()
    }

    var clueText: String {
        guard let question = currentQuestion else { return "" }
        return question.clue
    }

    var extendedClueText: String? {
        guard isShowingExtendedClue, let question = currentQuestion else { return nil }
        return question.extendedClue
    }

    var keyboardLetters: [String] {
        TurkishAlphabet.qKeyboardRows.flatMap { $0 }.filter { !removedKeyboardLetters.contains($0) }
    }

    var isAnswerWindowActive: Bool {
        answerWindowRemaining > 0
    }

    var isMainTimerCritical: Bool {
        result == nil && !isAnswerWindowActive && timeRemaining <= 10 && timeRemaining > 0
    }

    var canRevealLetter: Bool {
        result == nil && hasHiddenLetter && !isRevealingLetter && !isAnswerWindowActive
    }

    var canExtendClassicClue: Bool {
        mode == .classic && !isShowingExtendedClue && result == nil && inventoryCount(for: .extendClue) > 0
    }

    var canPassQuestion: Bool {
        mode == .privateChallenge && result == nil && remainingPasses > 0 && !isAnswerWindowActive
    }

    var challengeTitle: String? {
        privateChallenge?.title ?? selectedCategory.map { "\($0) kategorisi" }
    }

    var comboText: String? {
        guard comboMultiplier > 1 else { return nil }
        return "Kombo x\(comboMultiplier)"
    }

    func start() {
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()
        autoFailTask?.cancel()
        revealCooldownTask?.cancel()
        answerWindowRemaining = 0
        clearEnteredAnswer()
        selectedAnswerIndex = nil
        animationEvent = nil
        isTimeFrozen = false
        isRevealingLetter = false
        if let privateChallenge {
            let sharedQuestions = questionService.questions(matching: privateChallenge.questionIDs)
            questions = sharedQuestions.isEmpty
                ? questionService.privateChallengeQuestions(count: privateChallenge.questionIDs.count, maxDifficulty: privateChallenge.maxDifficulty)
                : sharedQuestions
        } else {
            switch mode {
            case .classic:
                questions = questionService.classicQuestions(maxDifficulty: level)
            case .categoryChallenge:
                questions = questionService.categoryQuestions(
                    category: selectedCategory ?? "",
                    level: level,
                    count: requestedQuestionCount ?? min(5 + level, 8)
                )
            case .challenge:
                questions = questionService.challengeQuestions(level: level)
            case .daily:
                questions = questionService.dailyQuestions(for: Date())
            case .quickTour:
                questions = questionService.quickTourQuestions()
            case .privateChallenge:
                questions = questionService.privateChallengeQuestions(count: 16, maxDifficulty: 3)
            }
        }
        if mode == .daily {
            scoreService.markDailyStarted(date: Date())
        }
        currentIndex = 0
        score = 0
        coins = scoreService.coins
        tileSkin = scoreService.selectedTileSkin
        refreshJokerInventory()
        coinMessage = nil
        lastChallengeCoinReward = 0
        hasPlayedMainTension = false
        correctCount = 0
        wrongCount = 0
        revealedLetterCount = 0
        comboStreak = 0
        maxCombo = 0
        remainingPasses = privateChallenge?.passLimit ?? 0
        fastestCorrectThisRun = nil
        usedJokers = []
        result = nil
        timeRemaining = privateChallenge?.totalTime ?? initialDuration
        prepareCurrentQuestion()
        startMainTimer()
    }

    func abandonDailyRun() {
        guard mode == .daily else { return }
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()
        autoFailTask?.cancel()
        revealCooldownTask?.cancel()
        scoreService.abandonDaily(date: Date())
    }

    func appendLetter(_ letter: String) {
        guard result == nil else { return }
        if requiresAnswerWindow, !isAnswerWindowActive {
            startAnswerWindow()
        }

        if let selectedAnswerIndex, replaceHiddenLetter(at: selectedAnswerIndex, with: letter) {
            selectNextEditableSlot(after: selectedAnswerIndex)
            return
        }

        guard let nextIndex = firstEmptyEditableIndex() else { return }
        _ = replaceHiddenLetter(at: nextIndex, with: letter)
        selectFirstEmptyEditableSlot()
    }

    func deleteLastLetter() {
        if let selectedAnswerIndex, removeHiddenLetter(at: selectedAnswerIndex) {
            return
        }

        guard let lastIndex = lastFilledEditableIndex() else { return }
        _ = removeHiddenLetter(at: lastIndex)
        selectFirstEmptyEditableSlot()
    }

    func selectAnswerSlot(at index: Int) {
        guard let question = currentQuestion,
              question.answer.turkishLetters.indices.contains(index),
              !openedIndices.contains(index) else {
            selectedAnswerIndex = nil
            return
        }
        selectedAnswerIndex = index
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
        guard scoreService.spendInventory(for: .extendClue) else {
            refreshJokerInventory()
            return
        }
        refreshJokerInventory()
        isShowingExtendedClue = true
        soundService.playJoker()
        animationEvent = .joker(.extendClue)
    }

    func submitAnswer() {
        guard let question = currentQuestion, result == nil else { return }
        guard !requiresAnswerWindow || isAnswerWindowActive else { return }

        if composedAnswerText.turkishGameNormalized() == question.answer.turkishGameNormalized() {
            let earnedPoints = currentPotentialScore * comboMultiplier
            score += earnedPoints
            correctCount += 1
            trackFastAnswerIfNeeded()
            updateComboAfterCorrectAnswer()
            soundService.playCorrect()
            soundService.playWordReveal()
            openedIndices = Set(question.answer.turkishLetters.indices)
            clearEnteredAnswer()
            selectedAnswerIndex = nil
            animationEvent = .correct(word: question.answer, points: earnedPoints)
            moveToNextQuestionAfterDelay(seconds: 1.25)
        } else {
            wrongCount += 1
            comboStreak = 0
            soundService.playWrong()
            openedIndices = Set(question.answer.turkishLetters.indices)
            clearEnteredAnswer()
            selectedAnswerIndex = nil
            animationEvent = .wrong(word: question.answer)
            moveToNextQuestionAfterDelay(seconds: 1.65)
        }
    }

    func passQuestion() {
        guard canPassQuestion, let question = currentQuestion else { return }
        remainingPasses -= 1
        wrongCount += 1
        comboStreak = 0
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        soundService.playWrong()
        openedIndices = Set(question.answer.turkishLetters.indices)
        clearEnteredAnswer()
        selectedAnswerIndex = nil
        animationEvent = .wrong(word: question.answer)
        moveToNextQuestionAfterDelay(seconds: 1.25)
    }

    func revealLetter() {
        guard canRevealLetter else { return }
        guard let question = currentQuestion else { return }
        let hidden = question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }
        guard let index = hidden.randomElement() else { return }
        openLetter(at: index, countsAsReveal: true)
    }

    func useJoker(_ joker: JokerType) {
        guard usesChallengeRules, result == nil, isJokerEnabled(joker) else { return }
        guard scoreService.spendInventory(for: joker) else {
            coinMessage = "Bu joker hakkın yok. Mağazadan altınla alabilirsin."
            soundService.playInsufficientCoins()
            animationEvent = .insufficientCoins
            refreshJokerInventory()
            return
        }
        refreshJokerInventory()

        switch joker {
        case .revealLetter:
            guard hasHiddenLetter else {
                refundJokerInventory(joker)
                return
            }
            revealLetter()
        case .firstLetter:
            guard !openedIndices.contains(0) else {
                refundJokerInventory(joker)
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

    func grantRewardedAdCoins() {
        scoreService.addCoins(6)
        coins = scoreService.coins
        coinMessage = "Reklam ödülü: +6 altın"
    }

    func markRewardedAdUnavailable() {
        coinMessage = "Reklam hazır değil. Biraz sonra tekrar deneyebilirsin."
        soundService.playInsufficientCoins()
        animationEvent = .insufficientCoins
    }

    func isJokerEnabled(_ joker: JokerType) -> Bool {
        guard usesChallengeRules, inventoryCount(for: joker) > 0 else { return false }
        switch joker {
        case .revealLetter: return hasHiddenLetter && !isRevealingLetter && !isAnswerWindowActive
        case .firstLetter: return !openedIndices.contains(0) && !isRevealingLetter && !isAnswerWindowActive
        case .removeWrongLetters: return removedKeyboardLetters.isEmpty
        case .freezeTime: return !isTimeFrozen && !isAnswerWindowActive
        case .extendClue: return !isShowingExtendedClue
        }
    }

    func inventoryCount(for joker: JokerType) -> Int {
        jokerInventory[joker, default: 0]
    }

    private var hasHiddenLetter: Bool {
        guard let question = currentQuestion else { return false }
        return openedIndices.count < question.letterCount
    }

    private var requiresAnswerWindow: Bool {
        true
    }

    var usesChallengeRules: Bool {
        mode == .challenge || mode == .categoryChallenge
    }

    private var allowsComboScoring: Bool {
        mode == .challenge || mode == .categoryChallenge || mode == .daily || mode == .quickTour
    }

    private var comboMultiplier: Int {
        guard allowsComboScoring else { return 1 }
        if comboStreak >= 4 { return 3 }
        if comboStreak >= 2 { return 2 }
        return 1
    }

    private var maxHiddenLetterCount: Int {
        guard let question = currentQuestion else { return 0 }
        return question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }.count
    }

    private func refundJokerInventory(_ joker: JokerType) {
        scoreService.addInventory(1, for: joker)
        refreshJokerInventory()
    }

    private func refreshJokerInventory() {
        jokerInventory = Dictionary(uniqueKeysWithValues: JokerType.allCases.map { ($0, scoreService.inventoryCount(for: $0)) })
        coins = scoreService.coins
    }

    private func openLetter(at index: Int, countsAsReveal: Bool) {
        guard let question = currentQuestion,
              question.answer.turkishLetters.indices.contains(index),
              !isRevealingLetter else { return }
        isRevealingLetter = true
        openedIndices.insert(index)
        enteredAnswerLetters.removeValue(forKey: index)
        syncAnswerText()
        if countsAsReveal {
            revealedLetterCount += 1
        }
        if selectedAnswerIndex == index || selectedAnswerIndex.map({ openedIndices.contains($0) }) == true {
            selectFirstEmptyEditableSlot()
        }
        soundService.playLetterReveal()
        animationEvent = .reveal(index: index, letter: question.answer.turkishLetters[index])
        releaseRevealCooldown(for: questionRevision)
        if countsAsReveal && !hasHiddenLetter {
            scheduleFullyRevealedFailure()
        }
    }

    private func releaseRevealCooldown(for revision: UUID) {
        revealCooldownTask?.cancel()
        revealCooldownTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(680))
            await MainActor.run {
                guard self?.questionRevision == revision else { return }
                self?.isRevealingLetter = false
            }
        }
    }

    private func scheduleFullyRevealedFailure() {
        let revision = questionRevision
        autoFailTask?.cancel()
        autoFailTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.75))
            await MainActor.run {
                guard self?.questionRevision == revision else { return }
                self?.failFullyRevealedQuestion()
            }
        }
    }

    private func failFullyRevealedQuestion() {
        guard let question = currentQuestion, result == nil, !hasHiddenLetter else { return }
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        wrongCount += 1
        comboStreak = 0
        score = max(0, score - 100)
        soundService.playWrong()
        openedIndices = Set(question.answer.turkishLetters.indices)
        clearEnteredAnswer()
        selectedAnswerIndex = nil
        animationEvent = .failed(word: question.answer, penalty: 100)
        moveToNextQuestionAfterDelay(seconds: 1.55)
    }

    private func removeWrongKeyboardLetters() {
        guard let question = currentQuestion else { return }
        let answerLetters = Set(question.answer.turkishLetters)
        let removable = TurkishAlphabet.qKeyboardRows.flatMap { $0 }.filter { !answerLetters.contains($0) }.shuffled()
        removedKeyboardLetters = Set(removable.prefix(8))
    }

    private func hiddenOrdinal(for answerIndex: Int) -> Int? {
        guard let question = currentQuestion,
              question.answer.turkishLetters.indices.contains(answerIndex),
              !openedIndices.contains(answerIndex) else { return nil }

        return question.answer.turkishLetters.indices
            .filter { !openedIndices.contains($0) && $0 < answerIndex }
            .count
    }

    private func replaceHiddenLetter(at answerIndex: Int, with letter: String) -> Bool {
        guard hiddenOrdinal(for: answerIndex) != nil else { return false }
        enteredAnswerLetters[answerIndex] = letter
        syncAnswerText()
        return true
    }

    private func removeHiddenLetter(at answerIndex: Int) -> Bool {
        guard hiddenOrdinal(for: answerIndex) != nil,
              enteredAnswerLetters.removeValue(forKey: answerIndex) != nil else { return false }
        syncAnswerText()
        return true
    }

    private func selectNextEditableSlot(after index: Int) {
        guard let question = currentQuestion else {
            selectedAnswerIndex = nil
            return
        }

        let hiddenIndices = question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }
        selectedAnswerIndex = hiddenIndices.first { candidate in
            candidate > index && enteredAnswerLetters[candidate] == nil
        } ?? hiddenIndices.first { enteredAnswerLetters[$0] == nil }
    }

    private func selectFirstEmptyEditableSlot() {
        guard let question = currentQuestion else {
            selectedAnswerIndex = nil
            return
        }

        let hiddenIndices = question.answer.turkishLetters.indices.filter { !openedIndices.contains($0) }
        selectedAnswerIndex = hiddenIndices.first { enteredAnswerLetters[$0] == nil }
    }

    private func firstEmptyEditableIndex() -> Int? {
        guard let question = currentQuestion else { return nil }
        return question.answer.turkishLetters.indices
            .filter { !openedIndices.contains($0) }
            .first { enteredAnswerLetters[$0] == nil }
    }

    private func lastFilledEditableIndex() -> Int? {
        guard let question = currentQuestion else { return nil }
        return question.answer.turkishLetters.indices
            .filter { !openedIndices.contains($0) && enteredAnswerLetters[$0] != nil }
            .last
    }

    private func syncAnswerText() {
        guard let question = currentQuestion else {
            answerText = ""
            return
        }
        answerText = question.answer.turkishLetters.indices
            .compactMap { openedIndices.contains($0) ? nil : enteredAnswerLetters[$0] }
            .joined()
    }

    private func clearEnteredAnswer() {
        enteredAnswerLetters = [:]
        answerText = ""
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

        if timeRemaining <= 10 && timeRemaining > 0 {
            if !hasPlayedMainTension {
                hasPlayedMainTension = true
                soundService.playTension()
            }
            soundService.playTick()
        }

        if timeRemaining == 0 {
            soundService.playWrong()
            finishGame()
        }
    }

    private func startAnswerWindow() {
        guard result == nil else { return }
        let revision = questionRevision
        answerWindowRemaining = 15
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

        if answerWindowRemaining == 0 {
            soundService.playTension()
            expireAnswerWindow()
        }
    }

    private func expireAnswerWindow() {
        guard let question = currentQuestion, result == nil else { return }
        answerTimerTask?.cancel()
        answerWindowRemaining = 0
        wrongCount += 1
        comboStreak = 0
        soundService.playWrong()
        openedIndices = Set(question.answer.turkishLetters.indices)
        clearEnteredAnswer()
        selectedAnswerIndex = nil
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
            clearQuestionEntryState(cancelPendingTasks: true)
            currentIndex += 1
            prepareCurrentQuestion()
        }
    }

    private func clearQuestionEntryState(cancelPendingTasks: Bool = false) {
        if cancelPendingTasks {
            answerTimerTask?.cancel()
            autoFailTask?.cancel()
            revealCooldownTask?.cancel()
            freezeTask?.cancel()
        }
        openedIndices = []
        clearEnteredAnswer()
        selectedAnswerIndex = nil
        removedKeyboardLetters = []
        isShowingExtendedClue = false
        isRevealingLetter = false
        isTimeFrozen = false
        coinMessage = nil
        animationEvent = nil
    }

    private func prepareCurrentQuestion() {
        questionRevision = UUID()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        autoFailTask?.cancel()
        revealCooldownTask?.cancel()
        answerWindowRemaining = 0
        openedIndices = []
        clearEnteredAnswer()
        selectedAnswerIndex = nil
        removedKeyboardLetters = []
        isTimeFrozen = false
        isRevealingLetter = false
        isShowingExtendedClue = false
        coinMessage = nil
        animationEvent = .reset(wordLength: currentQuestion?.letterCount ?? 0, id: questionRevision)
    }

    private func finishGame() {
        timerTask?.cancel()
        answerTimerTask?.cancel()
        advanceTask?.cancel()
        freezeTask?.cancel()
        autoFailTask?.cancel()
        revealCooldownTask?.cancel()

        let stars = usesChallengeRules || mode == .daily ? calculateStars() : 0
        let unlockedBadges = unlockEarnedBadges()
        let badgeCoinReward = unlockedBadges.reduce(0) { $0 + $1.rewardCoins }
        lastChallengeCoinReward = usesChallengeRules ? calculateCoinReward(stars: stars) : 0
        if lastChallengeCoinReward > 0 {
            scoreService.addCoins(lastChallengeCoinReward)
            coins = scoreService.coins
        }
        if badgeCoinReward > 0 {
            scoreService.addCoins(badgeCoinReward)
            coins = scoreService.coins
        }
        let personalMoments = buildPersonalMoments()
        let finalResult = GameResult(
            mode: mode,
            score: score,
            correctCount: correctCount,
            wrongCount: wrongCount,
            revealedLetterCount: revealedLetterCount,
            stars: stars,
            maxCombo: maxCombo,
            unlockedBadges: unlockedBadges,
            badgeCoinReward: badgeCoinReward,
            personalMoments: personalMoments
        )

        if mode == .classic {
            scoreService.saveClassicScore(score)
        } else if mode == .challenge {
            scoreService.saveStars(stars, forLevel: level)
        } else if mode == .categoryChallenge, stars > 0, let selectedCategory {
            let categories = questionService.categoryCounts()
            if let index = categories.firstIndex(where: { $0.category == selectedCategory }) {
                scoreService.completeCategoryMapNode(at: index, stars: stars)
            }
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
        guard usesChallengeRules else { return 0 }
        switch stars {
        case 3: return 5
        case 2: return 3
        case 1: return 1
        default: return 0
        }
    }

    private func challengeDuration(for difficulty: Int) -> Int {
        max(120 - (min(max(difficulty, 1), 5) - 1) * 10, 80)
    }

    private var initialDuration: Int {
        if mode == .classic { return 180 }
        if mode == .daily { return 120 }
        if mode == .quickTour { return 60 }
        return challengeDuration(for: level)
    }

    private func updateComboAfterCorrectAnswer() {
        guard allowsComboScoring else { return }
        comboStreak += 1
        maxCombo = max(maxCombo, comboStreak)
    }

    private func trackFastAnswerIfNeeded() {
        guard answerWindowRemaining > 0 else { return }
        let elapsed = max(1, 15 - answerWindowRemaining)
        fastestCorrectThisRun = min(fastestCorrectThisRun ?? elapsed, elapsed)
    }

    private func buildPersonalMoments() -> [String] {
        var moments: [String] = []

        if mode == .classic && score > scoreService.classicHighScore {
            moments.append("Yeni klasik rekor: \(score) puan")
        }

        if let fastestCorrectThisRun,
           scoreService.saveFastestCorrect(seconds: fastestCorrectThisRun) {
            moments.append("En hızlı doğru: \(fastestCorrectThisRun) sn")
        }

        if correctCount >= 5 && revealedLetterCount == 0 {
            moments.append("Harf almadan \(correctCount) doğru")
        }

        if allowsComboScoring && maxCombo >= 3 {
            moments.append("Kombo serisi: \(maxCombo) doğru")
        }

        if mode == .quickTour {
            moments.append("Hızlı Tur: \(correctCount) kelime")
        }

        return moments
    }

    private func unlockEarnedBadges() -> [BadgeType] {
        var unlocked: [BadgeType] = []

        if correctCount >= 5, revealedLetterCount == 0, scoreService.unlockBadge(.noHintRun) {
            unlocked.append(.noHintRun)
        }

        if mode == .categoryChallenge, correctCount >= 4, scoreService.unlockBadge(.categoryExpert) {
            unlocked.append(.categoryExpert)
        }

        if allowsComboScoring, maxCombo >= 3, scoreService.unlockBadge(.comboMaster) {
            unlocked.append(.comboMaster)
        }

        if mode == .daily {
            let streak = scoreService.updateDailyStreakIfNeeded(for: Date())
            if streak >= 10, scoreService.unlockBadge(.dailyStreak) {
                unlocked.append(.dailyStreak)
            }
        }

        return unlocked
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
