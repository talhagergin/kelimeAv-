import SwiftUI

struct TurkishKeyboardView: View {
    let letters: [String]
    var keyHeight: CGFloat = 36
    let onTap: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(TurkishAlphabet.qKeyboardRows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 5) {
                    ForEach(row.filter { letters.contains($0) }, id: \.self) { letter in
                        Button {
                            onTap(letter)
                        } label: {
                            keyLabel(letter)
                        }
                        .buttonStyle(.plain)
                    }

                    if rowIndex == TurkishAlphabet.qKeyboardRows.count - 1 {
                        Button(action: onDelete) {
                            Image(systemName: "delete.left.fill")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: keyHeight)
                                .background(GameTheme.orange.opacity(0.95), in: RoundedRectangle(cornerRadius: 9))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(9)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        )
    }

    private func keyLabel(_ letter: String) -> some View {
        Text(letter)
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(GameTheme.blue.opacity(0.86), in: RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
    }
}
