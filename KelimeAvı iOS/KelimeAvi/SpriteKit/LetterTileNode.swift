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

    func applySkin(_ skin: TileSkin) {
        box.fillColor = skin.spriteFillColor
        box.strokeColor = skin.spriteStrokeColor
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

private extension TileSkin {
    var spriteFillColor: SKColor {
        switch self {
        case .classicBlue: return SKColor(red: 0.12, green: 0.24, blue: 0.55, alpha: 1)
        case .royalPurple: return SKColor(red: 0.36, green: 0.11, blue: 0.72, alpha: 1)
        case .sunset: return SKColor(red: 0.88, green: 0.25, blue: 0.12, alpha: 1)
        case .mint: return SKColor(red: 0.04, green: 0.54, blue: 0.44, alpha: 1)
        case .ruby: return SKColor(red: 0.74, green: 0.02, blue: 0.14, alpha: 1)
        case .emerald: return SKColor(red: 0.02, green: 0.50, blue: 0.24, alpha: 1)
        case .ocean: return SKColor(red: 0.02, green: 0.34, blue: 0.76, alpha: 1)
        case .lemon: return SKColor(red: 0.84, green: 0.52, blue: 0.04, alpha: 1)
        case .graphite: return SKColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1)
        case .candy: return SKColor(red: 0.78, green: 0.18, blue: 0.66, alpha: 1)
        case .galaxy: return SKColor(red: 0.14, green: 0.04, blue: 0.46, alpha: 1)
        case .neon: return SKColor(red: 0.02, green: 0.62, blue: 0.70, alpha: 1)
        case .ice: return SKColor(red: 0.22, green: 0.58, blue: 0.84, alpha: 1)
        case .rose: return SKColor(red: 0.72, green: 0.12, blue: 0.34, alpha: 1)
        }
    }

    var spriteStrokeColor: SKColor {
        switch self {
        case .classicBlue, .royalPurple: return SKColor(red: 1.0, green: 0.78, blue: 0.18, alpha: 1)
        case .sunset: return SKColor(red: 1.0, green: 0.88, blue: 0.42, alpha: 1)
        case .mint: return SKColor(red: 0.72, green: 1.0, blue: 0.86, alpha: 1)
        case .ruby: return SKColor(red: 1.0, green: 0.52, blue: 0.58, alpha: 1)
        case .emerald: return SKColor(red: 0.58, green: 1.0, blue: 0.72, alpha: 1)
        case .ocean: return SKColor(red: 0.54, green: 0.88, blue: 1.0, alpha: 1)
        case .lemon: return SKColor.white
        case .graphite: return SKColor(red: 0.76, green: 0.76, blue: 0.84, alpha: 1)
        case .candy: return SKColor(red: 1.0, green: 0.72, blue: 0.94, alpha: 1)
        case .galaxy: return SKColor(red: 0.90, green: 0.72, blue: 1.0, alpha: 1)
        case .neon: return SKColor(red: 0.56, green: 1.0, blue: 0.95, alpha: 1)
        case .ice: return SKColor.white
        case .rose: return SKColor(red: 1.0, green: 0.70, blue: 0.82, alpha: 1)
        }
    }
}
