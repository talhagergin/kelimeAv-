import SpriteKit

final class GameScene: SKScene {
    private var tiles: [LetterTileNode] = []
    private let backgroundNode = SKShapeNode()
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let wordRevealActionKey = "wordReveal"
    private let letterRevealActionKey = "letterReveal"

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.13, green: 0.06, blue: 0.30, alpha: 1)
    }

    class func newGameScene() -> GameScene {
        GameScene(size: CGSize(width: 360, height: 200))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupScoreLabel()
    }

    func configure(wordLength: Int) {
        removeAction(forKey: wordRevealActionKey)
        removeAction(forKey: letterRevealActionKey)
        scoreLabel.removeAllActions()
        scoreLabel.text = ""
        scoreLabel.alpha = 0
        tiles.forEach { $0.removeFromParent() }
        tiles = []

        guard wordLength > 0 else { return }

        let spacing: CGFloat = 8
        let maxTileWidth = (size.width - CGFloat(wordLength - 1) * spacing - 24) / CGFloat(wordLength)
        let tileSide = min(maxTileWidth, 46)
        let totalWidth = CGFloat(wordLength) * tileSide + CGFloat(wordLength - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + tileSide / 2

        for index in 0..<wordLength {
            let tile = LetterTileNode(size: CGSize(width: tileSide, height: tileSide))
            tile.position = CGPoint(x: startX + CGFloat(index) * (tileSide + spacing), y: size.height * 0.58)
            addChild(tile)
            tiles.append(tile)
        }
    }

    func revealLetter(at index: Int, letter: String) {
        guard tiles.indices.contains(index) else { return }
        let alphabet = TurkishAlphabet.letters.shuffled()
        var actions: [SKAction] = alphabet.map { candidate in
            .sequence([
                .run { [weak self] in
                    self?.tiles[index].setLetter(candidate, animated: false)
                    self?.tiles[index].glow(color: SKColor(red: 1.0, green: 0.73, blue: 0.1, alpha: 1))
                },
                .wait(forDuration: 0.018)
            ])
        }
        actions.append(.run { [weak self] in
            self?.tiles[index].setLetter(letter, animated: true)
            self?.tiles[index].glow(color: SKColor(red: 1.0, green: 0.73, blue: 0.1, alpha: 1))
        })
        run(.sequence(actions), withKey: letterRevealActionKey)
    }

    func playCorrect(points: Int) {
        tiles.forEach { $0.glow(color: SKColor(red: 0.12, green: 0.82, blue: 0.38, alpha: 1)) }
        scoreLabel.text = "+\(points)"
        scoreLabel.alpha = 1
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        scoreLabel.run(.sequence([
            .group([.moveBy(x: 0, y: 30, duration: 0.45), .fadeOut(withDuration: 0.45)]),
            .run { [weak self] in self?.scoreLabel.text = "" }
        ]))
    }

    func revealWord(_ word: String, points: Int) {
        revealWord(word, points: points, color: SKColor(red: 0.12, green: 0.82, blue: 0.38, alpha: 1), showPoints: true)
    }

    func revealWrongWord(_ word: String) {
        revealWord(word, points: 0, color: SKColor(red: 0.95, green: 0.14, blue: 0.14, alpha: 1), showPoints: false)
        playWrong()
    }

    private func revealWord(_ word: String, points: Int, color: SKColor, showPoints: Bool) {
        removeAction(forKey: wordRevealActionKey)
        removeAction(forKey: letterRevealActionKey)
        var actions: [SKAction] = []

        for (index, letter) in word.turkishLetters.enumerated() where tiles.indices.contains(index) {
            let wait = SKAction.wait(forDuration: Double(index) * 0.045)
            let reveal = SKAction.run { [weak self] in
                self?.tiles[index].setLetter(letter, animated: true)
                self?.tiles[index].glow(color: color)
            }
            actions.append(.sequence([wait, reveal]))
        }

        if showPoints {
            actions.append(.sequence([
                .wait(forDuration: Double(word.count) * 0.045 + 0.1),
                .run { [weak self] in self?.playCorrect(points: points) }
            ]))
        }

        run(.group(actions), withKey: wordRevealActionKey)
    }

    func playWrong() {
        tiles.forEach { $0.shake() }
    }

    func setLowTime(_ active: Bool) {
        let color = active
            ? SKColor(red: 0.50, green: 0.05, blue: 0.18, alpha: 1)
            : SKColor(red: 0.13, green: 0.06, blue: 0.30, alpha: 1)
        backgroundColor = color
    }

    func playJoker(_ joker: JokerType) {
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        ring.strokeColor = .cyan
        ring.lineWidth = 4
        ring.alpha = 0.9
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 4, duration: 0.45), .fadeOut(withDuration: 0.45)]),
            .removeFromParent()
        ]))
    }

    private func setupBackground() {
        backgroundNode.removeFromParent()
        backgroundNode.path = CGPath(
            roundedRect: CGRect(x: 12, y: 12, width: size.width - 24, height: size.height - 24),
            cornerWidth: 22,
            cornerHeight: 22,
            transform: nil
        )
        backgroundNode.fillColor = SKColor(red: 0.24, green: 0.14, blue: 0.54, alpha: 0.86)
        backgroundNode.strokeColor = SKColor(red: 1.0, green: 0.75, blue: 0.14, alpha: 0.50)
        backgroundNode.lineWidth = 2
        backgroundNode.zPosition = -1
        addChild(backgroundNode)
    }

    private func setupScoreLabel() {
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.83, blue: 0.17, alpha: 1)
        scoreLabel.alpha = 0
        addChild(scoreLabel)
    }
}
