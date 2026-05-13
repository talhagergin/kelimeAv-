import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "timer",
            title: "Süreyi Yakala",
            text: "Klasik modda süreyi durdur, kalan cevap süresinde kelimeyi tamamla ve yüksek puanı kovala."
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Harfleri Akıllıca Aç",
            text: "Aldığın her harf puanı düşürür. Kutulardaki boşlukları klavyeyle doldur, cevabı oradan gönder."
        ),
        OnboardingPage(
            icon: "crown.fill",
            title: "Bölüm ve Altın",
            text: "Bölüm modlarından altın kazan, jokerleri mağazadan al ve zor sorularda avantaj yarat."
        )
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            Text("Kelime Avı")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 20) {
                        Image(systemName: item.icon)
                            .font(.system(size: 58, weight: .black))
                            .foregroundStyle(GameTheme.yellow)
                            .frame(width: 112, height: 112)
                            .background(.white.opacity(0.12), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1.5))

                        VStack(spacing: 10) {
                            Text(item.title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.white)

                            Text(item.text)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 22)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 360)

            Button {
                if page < pages.count - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        page += 1
                    }
                } else {
                    onFinished()
                }
            } label: {
                Text(page == pages.count - 1 ? "Oyuna Başla" : "Devam")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(GameTheme.blue, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            }

            Button("Geç") {
                onFinished()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.68))

            Spacer(minLength: 18)
        }
        .padding(.horizontal, 26)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let text: String
}
