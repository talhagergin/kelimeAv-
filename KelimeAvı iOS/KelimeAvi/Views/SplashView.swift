import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    @State private var scale = 0.7
    @State private var opacity = 0.0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "textformat.abc")
                .font(.system(size: 76, weight: .black))
                .foregroundStyle(GameTheme.yellow)
                .scaleEffect(scale)

            Text("Kelime Avı")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Harfleri aç, zamanı yakala")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                scale = 1
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: onFinished)
        }
    }
}
