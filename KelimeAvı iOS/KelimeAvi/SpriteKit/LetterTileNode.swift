import SpriteKit

final class LetterTileNode: SKNode {
    private let box: SKShapeNode
    private let label: SKLabelNode

    init(size: CGSize) {
        box = SKShapeNode(rectOf: size, cornerRadius: 10)
        label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        super.init()

        box.fillColor = SKColor(red: 0.12, green: 0.24, blue: 0.55, alpha: 1)
        box.strokeColor = SKColor(red: 1.0, green: 0.78, blue: 0.18, alpha: 1)
        box.lineWidth = 3

        label.fontSize = size.height * 0.52
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = .white
        label.text = ""

        addChild(box)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLetter(_ letter: String, animated: Bool) {
        label.text = letter
        guard animated else { return }
        setScale(0.2)
        alpha = 0.2
        run(.group([
            .fadeIn(withDuration: 0.18),
            .scale(to: 1.0, duration: 0.22)
        ]))
    }

    func glow(color: SKColor) {
        box.run(.sequence([
            .colorize(with: color, colorBlendFactor: 0.9, duration: 0.12),
            .colorize(withColorBlendFactor: 0, duration: 0.25)
        ]))
    }

    func shake() {
        let sequence = SKAction.sequence([
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 16, y: 0, duration: 0.08),
            .moveBy(x: -8, y: 0, duration: 0.04)
        ])
        run(sequence)
    }
}
