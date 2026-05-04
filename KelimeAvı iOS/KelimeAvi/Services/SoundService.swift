import AVFoundation
import UIKit

protocol SoundPlaying {
    func playCorrect()
    func playWrong()
    func playTension()
    func playTick()
    func playLetterReveal()
    func playWordReveal()
    func playJoker()
    func playInsufficientCoins()
}

final class SoundService: SoundPlaying {
    func playCorrect() {
        AudioServicesPlaySystemSound(1025)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func playWrong() {
        AudioServicesPlaySystemSound(1053)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func playTension() {
        AudioServicesPlaySystemSound(1057)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func playTick() {
        AudioServicesPlaySystemSound(1104)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func playLetterReveal() {
        AudioServicesPlaySystemSound(1105)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func playWordReveal() {
        AudioServicesPlaySystemSound(1022)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func playJoker() {
        AudioServicesPlaySystemSound(1113)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func playInsufficientCoins() {
        AudioServicesPlaySystemSound(1050)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
