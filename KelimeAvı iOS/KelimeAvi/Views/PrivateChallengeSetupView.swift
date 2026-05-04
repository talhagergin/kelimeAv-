import SwiftUI

struct PrivateChallengeSetupView: View {
    let onStart: (PrivateChallenge) -> Void
    let onBack: () -> Void

    @State private var creatorName = ""
    @State private var questionCount = 10
    @State private var totalTime = 180
    @State private var maxDifficulty = 3
    @State private var generatedChallenge: PrivateChallenge?
    @State private var incomingCode = ""
    @State private var errorMessage: String?

    private let service = PrivateChallengeService()

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760

            VStack(spacing: compact ? 12 : 16) {
                header

                VStack(spacing: compact ? 10 : 12) {
                    TextField("Adın", text: $creatorName)
                        .textInputAutocapitalization(.words)
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)

                    stepperRow(title: "Soru", value: "\(questionCount)", range: 6...14, binding: $questionCount)
                    stepperRow(title: "Süre", value: "\(totalTime) sn", range: 90...300, step: 30, binding: $totalTime)
                    stepperRow(title: "Zorluk", value: "\(maxDifficulty)/5", range: 1...5, binding: $maxDifficulty)

                    Button {
                        generatedChallenge = service.createChallenge(
                            creatorName: creatorName,
                            questionCount: questionCount,
                            totalTime: totalTime,
                            maxDifficulty: maxDifficulty
                        )
                        errorMessage = nil
                    } label: {
                        Label("Meydan Okuma Oluştur", systemImage: "bolt.fill")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))

                if let challenge = generatedChallenge {
                    generatedPanel(challenge)
                }

                VStack(spacing: 10) {
                    TextField("Gelen challenge linki veya kodu", text: $incomingCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)

                    Button {
                        openIncomingChallenge()
                    } label: {
                        Label("Kodu Aç", systemImage: "link")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, compact ? 12 : 18)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Private Challenge")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Aynı sorular, klasik kurallar, joker yok.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
    }

    private func stepperRow(
        title: String,
        value: String,
        range: ClosedRange<Int>,
        step: Int = 1,
        binding: Binding<Int>
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.62))
                Text(value)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }

            Spacer()

            Stepper("", value: binding, in: range, step: step)
                .labelsHidden()
                .tint(GameTheme.yellow)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
    }

    private func generatedPanel(_ challenge: PrivateChallenge) -> some View {
        let code = service.shareCode(for: challenge)
        let url = service.shareURL(for: challenge)

        return VStack(spacing: 10) {
            HStack {
                Label("\(challenge.questionIDs.count) soru", systemImage: "square.grid.2x2.fill")
                Spacer()
                Label("\(challenge.totalTime) sn", systemImage: "timer")
            }
            .font(.caption.weight(.black))
            .foregroundStyle(.white.opacity(0.74))

            Text(code)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(2)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                ShareLink(item: url) {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onStart(challenge)
                } label: {
                    Label("Başla", systemImage: "play.fill")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(GameTheme.yellow, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(GameTheme.yellow.opacity(0.24), lineWidth: 1))
    }

    private func openIncomingChallenge() {
        guard let challenge = service.challenge(from: incomingCode) else {
            errorMessage = "Challenge kodu okunamadı."
            return
        }
        errorMessage = nil
        onStart(challenge)
    }
}
