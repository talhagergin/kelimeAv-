import SwiftUI

struct TurkishKeyboardView: View {
    let letters: [String]
    var keyHeight: CGFloat = 36
    var skin: TileSkin = .classicBlue
    let onTap: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(TurkishAlphabet.qKeyboardRows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 6) {
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
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: keyHeight)
                                .background(GameTheme.orange.opacity(0.95), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(7)
        .background(skin.keyboardPanelColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(skin.keyboardStrokeColor.opacity(0.32), lineWidth: 1)
        )
    }

    private func keyLabel(_ letter: String) -> some View {
        Text(letter)
            .font(.title3.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(
                LinearGradient(
                    colors: [skin.keyboardKeyTopColor, skin.keyboardKeyBottomColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(skin.keyboardStrokeColor.opacity(0.38), lineWidth: 1)
            )
            .shadow(color: skin.keyboardKeyBottomColor.opacity(0.20), radius: 5, y: 3)
    }
}

private extension TileSkin {
    var keyboardPanelColor: Color {
        switch self {
        case .classicBlue: return .black.opacity(0.18)
        case .royalPurple: return Color(red: 0.18, green: 0.05, blue: 0.35).opacity(0.42)
        case .sunset: return Color(red: 0.38, green: 0.10, blue: 0.20).opacity(0.40)
        case .mint: return Color(red: 0.02, green: 0.25, blue: 0.22).opacity(0.38)
        case .ruby: return Color(red: 0.32, green: 0.02, blue: 0.08).opacity(0.42)
        case .emerald: return Color(red: 0.02, green: 0.24, blue: 0.12).opacity(0.42)
        case .ocean: return Color(red: 0.02, green: 0.18, blue: 0.34).opacity(0.42)
        case .lemon: return Color(red: 0.36, green: 0.30, blue: 0.02).opacity(0.34)
        case .graphite: return Color(red: 0.04, green: 0.04, blue: 0.06).opacity(0.52)
        case .candy: return Color(red: 0.34, green: 0.08, blue: 0.30).opacity(0.40)
        case .galaxy: return Color(red: 0.05, green: 0.02, blue: 0.16).opacity(0.54)
        case .neon: return Color(red: 0.02, green: 0.02, blue: 0.08).opacity(0.58)
        case .ice: return Color(red: 0.06, green: 0.22, blue: 0.30).opacity(0.36)
        case .rose: return Color(red: 0.38, green: 0.08, blue: 0.22).opacity(0.40)
        }
    }

    var keyboardKeyTopColor: Color {
        switch self {
        case .classicBlue: return GameTheme.blue.opacity(0.92)
        case .royalPurple: return Color(red: 0.58, green: 0.24, blue: 0.96)
        case .sunset: return Color(red: 1.00, green: 0.45, blue: 0.16)
        case .mint: return Color(red: 0.10, green: 0.76, blue: 0.62)
        case .ruby: return Color(red: 0.92, green: 0.10, blue: 0.22)
        case .emerald: return Color(red: 0.04, green: 0.72, blue: 0.32)
        case .ocean: return Color(red: 0.05, green: 0.56, blue: 0.92)
        case .lemon: return Color(red: 1.0, green: 0.82, blue: 0.12)
        case .graphite: return Color(red: 0.34, green: 0.34, blue: 0.40)
        case .candy: return Color(red: 1.0, green: 0.35, blue: 0.72)
        case .galaxy: return Color(red: 0.38, green: 0.12, blue: 0.92)
        case .neon: return Color(red: 0.10, green: 0.95, blue: 0.92)
        case .ice: return Color(red: 0.54, green: 0.88, blue: 1.0)
        case .rose: return Color(red: 0.96, green: 0.34, blue: 0.54)
        }
    }

    var keyboardKeyBottomColor: Color {
        switch self {
        case .classicBlue: return GameTheme.blue.opacity(0.76)
        case .royalPurple: return Color(red: 0.31, green: 0.10, blue: 0.68)
        case .sunset: return Color(red: 0.78, green: 0.18, blue: 0.18)
        case .mint: return Color(red: 0.04, green: 0.46, blue: 0.42)
        case .ruby: return Color(red: 0.54, green: 0.02, blue: 0.13)
        case .emerald: return Color(red: 0.02, green: 0.42, blue: 0.24)
        case .ocean: return Color(red: 0.02, green: 0.24, blue: 0.64)
        case .lemon: return Color(red: 0.78, green: 0.48, blue: 0.04)
        case .graphite: return Color(red: 0.10, green: 0.10, blue: 0.14)
        case .candy: return Color(red: 0.42, green: 0.22, blue: 0.95)
        case .galaxy: return Color(red: 0.04, green: 0.02, blue: 0.22)
        case .neon: return Color(red: 0.92, green: 0.10, blue: 0.92)
        case .ice: return Color(red: 0.10, green: 0.52, blue: 0.78)
        case .rose: return Color(red: 0.56, green: 0.08, blue: 0.30)
        }
    }

    var keyboardStrokeColor: Color {
        switch self {
        case .classicBlue, .royalPurple, .sunset: return GameTheme.yellow
        case .mint: return Color(red: 0.75, green: 1.0, blue: 0.88)
        case .ruby: return Color(red: 1.0, green: 0.58, blue: 0.58)
        case .emerald: return Color(red: 0.65, green: 1.0, blue: 0.76)
        case .ocean: return Color(red: 0.58, green: 0.88, blue: 1.0)
        case .lemon: return .white
        case .graphite: return Color(red: 0.82, green: 0.82, blue: 0.88)
        case .candy: return Color(red: 1.0, green: 0.78, blue: 0.95)
        case .galaxy: return Color(red: 0.94, green: 0.80, blue: 1.0)
        case .neon: return Color(red: 0.55, green: 1.0, blue: 0.98)
        case .ice: return .white
        case .rose: return Color(red: 1.0, green: 0.75, blue: 0.84)
        }
    }
}
