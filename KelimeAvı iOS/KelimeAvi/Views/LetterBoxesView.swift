import SwiftUI

struct LetterBoxesView: View {
    let letters: [String?]
    var height: CGFloat = 36

    var body: some View {
        HStack(spacing: 6) {
            ForEach(letters.indices, id: \.self) { index in
                Text(letters[index] ?? "")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(letters[index] == nil ? .white.opacity(0.10) : GameTheme.blue.opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GameTheme.yellow.opacity(0.75), lineWidth: 2)
                    )
            }
        }
        .frame(minHeight: height)
    }
}
