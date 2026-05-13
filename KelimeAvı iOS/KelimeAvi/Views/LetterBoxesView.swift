import SwiftUI

struct LetterBoxesView: View {
    let letters: [String?]
    var selectedIndex: Int?
    var height: CGFloat = 36
    var skin: TileSkin = .classicBlue
    var onTap: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            let spacing = letters.count >= 9 ? CGFloat(3) : CGFloat(6)
            let availableWidth = proxy.size.width - CGFloat(max(letters.count - 1, 0)) * spacing
            let widthMultiplier = letters.count >= 9 ? CGFloat(1.08) : CGFloat(1.22)
            let tileWidth = min(height * widthMultiplier, availableWidth / CGFloat(max(letters.count, 1)))
            let fontSize = max(14, min(20, tileWidth * 0.52))

            HStack(spacing: spacing) {
                ForEach(letters.indices, id: \.self) { index in
                    Button {
                        onTap(index)
                    } label: {
                        Text(letters[index] ?? "")
                            .font(.system(size: fontSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: tileWidth, height: height)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(letters[index] == nil ? skin.emptyColor : skin.filledColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedIndex == index ? .white : GameTheme.yellow.opacity(0.75), lineWidth: selectedIndex == index ? 3 : 2)
                            )
                            .shadow(color: selectedIndex == index ? GameTheme.yellow.opacity(0.45) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, minHeight: height, alignment: .center)
        }
        .frame(height: height)
    }
}

private extension TileSkin {
    var filledColor: Color {
        switch self {
        case .classicBlue: return GameTheme.blue.opacity(0.88)
        case .royalPurple: return Color(red: 0.45, green: 0.16, blue: 0.82).opacity(0.92)
        case .sunset: return GameTheme.orange.opacity(0.92)
        case .mint: return Color(red: 0.10, green: 0.70, blue: 0.56).opacity(0.92)
        case .ruby: return Color(red: 0.82, green: 0.05, blue: 0.18).opacity(0.92)
        case .emerald: return Color(red: 0.02, green: 0.62, blue: 0.30).opacity(0.92)
        case .ocean: return Color(red: 0.04, green: 0.44, blue: 0.86).opacity(0.92)
        case .lemon: return Color(red: 0.92, green: 0.62, blue: 0.06).opacity(0.92)
        case .graphite: return Color(red: 0.18, green: 0.18, blue: 0.23).opacity(0.94)
        case .candy: return Color(red: 0.88, green: 0.22, blue: 0.72).opacity(0.92)
        case .galaxy: return Color(red: 0.18, green: 0.07, blue: 0.56).opacity(0.94)
        case .neon: return Color(red: 0.04, green: 0.74, blue: 0.82).opacity(0.94)
        case .ice: return Color(red: 0.30, green: 0.70, blue: 0.94).opacity(0.90)
        case .rose: return Color(red: 0.82, green: 0.18, blue: 0.42).opacity(0.92)
        }
    }

    var emptyColor: Color {
        switch self {
        case .classicBlue: return .white.opacity(0.10)
        case .royalPurple: return Color(red: 0.54, green: 0.28, blue: 0.88).opacity(0.20)
        case .sunset: return Color(red: 1.0, green: 0.58, blue: 0.18).opacity(0.18)
        case .mint: return Color(red: 0.38, green: 0.95, blue: 0.78).opacity(0.16)
        case .ruby: return Color(red: 1.0, green: 0.22, blue: 0.32).opacity(0.16)
        case .emerald: return Color(red: 0.25, green: 0.95, blue: 0.48).opacity(0.16)
        case .ocean: return Color(red: 0.20, green: 0.70, blue: 1.0).opacity(0.16)
        case .lemon: return Color(red: 1.0, green: 0.86, blue: 0.20).opacity(0.18)
        case .graphite: return Color(red: 0.70, green: 0.70, blue: 0.78).opacity(0.14)
        case .candy: return Color(red: 1.0, green: 0.52, blue: 0.90).opacity(0.16)
        case .galaxy: return Color(red: 0.52, green: 0.25, blue: 1.0).opacity(0.18)
        case .neon: return Color(red: 0.0, green: 1.0, blue: 0.94).opacity(0.16)
        case .ice: return Color(red: 0.70, green: 0.92, blue: 1.0).opacity(0.18)
        case .rose: return Color(red: 1.0, green: 0.42, blue: 0.66).opacity(0.16)
        }
    }
}
