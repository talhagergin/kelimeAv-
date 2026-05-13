import SwiftUI
import UIKit

struct PrivateChallengeSetupView: View {
    let onStart: (PrivateChallenge) -> Void
    let onBack: () -> Void
    @ObservedObject private var adService = AdService.shared

    @State private var creatorName = ""
    @State private var questionCount = 16
    @State private var totalTime = 180
    @State private var maxDifficulty = 3
    @State private var passLimit = 0
    @State private var categories: [String] = ["Karışık"]
    @State private var selectedCategory = "Karışık"
    @State private var generatedChallenge: PrivateChallenge?
    @State private var incomingCode = ""
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var isCreatorPanelExpanded = true
    @State private var roomCreationsToday = 0
    @State private var roomAdWatchCount = 0
    @State private var isWatchingRoomAd = false
    @State private var showAllCategories = false
    @FocusState private var focusedField: Field?

    private let service = PrivateChallengeService()
    private let questionService = QuestionService()
    private let scoreService = ScoreService()
    private let freeRoomLimit = 5
    private let roomCost = 10
    private let requiredRoomAds = 2

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760

            ScrollView {
                VStack(spacing: compact ? 12 : 16) {
                    header

                    if isCreatorPanelExpanded || generatedChallenge == nil {
                    VStack(spacing: compact ? 10 : 12) {
                        TextField("Adın", text: $creatorName)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .creatorName)
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .onSubmit { focusedField = nil }

                        stepperRow(title: "Soru", value: "\(questionCount)", range: 6...16, binding: $questionCount)
                        stepperRow(title: "Süre", value: "\(totalTime) sn", range: 90...300, step: 30, binding: $totalTime)
                        stepperRow(title: "Zorluk", value: "\(maxDifficulty)/5", range: 1...5, binding: $maxDifficulty)
                        stepperRow(title: "Pas Hakkı", value: "\(passLimit)", range: 0...5, binding: $passLimit)
                        categoryGrid
                        roomQuotaView

                        Button {
                            focusedField = nil
                            createChallenge()
                        } label: {
                            Label(createButtonTitle, systemImage: "bolt.fill")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)

                        if roomCreationsToday >= freeRoomLimit && roomAdWatchCount < requiredRoomAds {
                            Button {
                                watchRoomAd()
                            } label: {
                                Label(roomAdButtonTitle, systemImage: adService.isRewardedAdReady ? "play.rectangle.fill" : "clock.fill")
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(adService.isRewardedAdReady ? .white.opacity(0.12) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(isWatchingRoomAd || !adService.isRewardedAdReady)
                            .opacity(isWatchingRoomAd || !adService.isRewardedAdReady ? 0.65 : 1)
                        }
                    }
                    .padding(14)
                    .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
                    } else {
                        collapsedCreatorPanel
                    }

                    if let challenge = generatedChallenge {
                        generatedPanel(challenge)
                    }

                    incomingPanel

                    if let message = errorMessage ?? statusMessage {
                        Text(message)
                            .font(.caption.weight(.black))
                            .foregroundStyle(GameTheme.yellow)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, compact ? 12 : 18)
                .padding(.bottom, 20)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                focusedField = nil
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Kapat") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                categories = ["Karışık"] + questionService.categoryCounts().map(\.category)
                roomCreationsToday = scoreService.privateRoomsCreatedToday(date: Date())
                AdService.shared.refreshRewardedAd()
            }
        }
        .swipeBackGesture(onBack)
    }

    private enum Field {
        case creatorName
        case incomingCode
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

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Kategori", systemImage: "tag.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.68))
                Spacer()
                Text(selectedCategory)
                    .font(.caption.weight(.black))
                    .foregroundStyle(GameTheme.yellow)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(visibleCategories, id: \.self) { category in
                    categoryChip(category)
                }
            }

            if categories.count > 6 {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        showAllCategories.toggle()
                    }
                } label: {
                    Label(showAllCategories ? "Kategorileri Kısalt" : "Tüm Kategoriler", systemImage: showAllCategories ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.yellow)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
    }

    private var visibleCategories: [String] {
        guard !showAllCategories else { return categories }
        var visible = Array(categories.prefix(6))
        if !visible.contains(selectedCategory) {
            visible.append(selectedCategory)
        }
        return visible
    }

    private func categoryChip(_ category: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Label(category, systemImage: category == "Karışık" ? "shuffle" : "tag.fill")
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .foregroundStyle(selectedCategory == category ? .black : .white)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    selectedCategory == category ? GameTheme.yellow : .white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 13)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(.white.opacity(selectedCategory == category ? 0 : 0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var roomQuotaView: some View {
        HStack(spacing: 10) {
            Image(systemName: roomCreationsToday < freeRoomLimit ? "gift.fill" : "lock.fill")
                .foregroundStyle(GameTheme.yellow)
            Text(roomQuotaText)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
    }

    private var collapsedCreatorPanel: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                isCreatorPanelExpanded = true
            }
        } label: {
            HStack {
                Label("Yeni meydan okuma oluştur", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.black))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.headline.weight(.black))
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
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

            Label("Pas hakkı: \(challenge.passLimit)", systemImage: "forward.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.74))
                .frame(maxWidth: .infinity, alignment: .leading)

            Label(challenge.category ?? "Karışık kategori", systemImage: challenge.category == nil ? "shuffle" : "tag.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(GameTheme.yellow)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(code)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
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
                    service.markJoined(challenge)
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

    private var incomingPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Gelen meydan okuma linki veya kodu", text: $incomingCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .incomingCode)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .onSubmit {
                        focusedField = nil
                    }
                    .contextMenu {
                        Button("Yapıştır") {
                            incomingCode = UIPasteboard.general.string ?? incomingCode
                        }
                    }

                Button {
                    incomingCode = UIPasteboard.general.string ?? incomingCode
                    focusedField = nil
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 44)
                        .background(GameTheme.orange, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button {
                focusedField = nil
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
    }

    private func openIncomingChallenge() {
        guard let challenge = service.challenge(from: incomingCode) else {
            errorMessage = "Meydan okuma kodu okunamadı."
            return
        }
        guard !service.hasJoined(challenge) else {
            errorMessage = "Bu meydan okumaya bu cihazdan daha önce girilmiş."
            return
        }
        service.markJoined(challenge)
        errorMessage = nil
        onStart(challenge)
    }

    private var createButtonTitle: String {
        if roomCreationsToday < freeRoomLimit {
            return "Meydan Okuma Oluştur"
        }
        if roomAdWatchCount >= requiredRoomAds {
            return "Reklam Hakkıyla Oluştur"
        }
        return "\(roomCost) Altınla Oluştur"
    }

    private var roomQuotaText: String {
        if roomCreationsToday < freeRoomLimit {
            return "Bugünkü ücretsiz oda hakkı: \(freeRoomLimit - roomCreationsToday)/\(freeRoomLimit)"
        }
        return "Ücretsiz hak bitti. 10 altınla oluştur veya 2 reklam izle."
    }

    private func createChallenge() {
        if roomCreationsToday >= freeRoomLimit && roomAdWatchCount < requiredRoomAds {
            guard scoreService.spendCoins(roomCost) else {
                statusMessage = "Yetersiz altın. 2 reklam izleyerek oda açabilirsin."
                errorMessage = nil
                return
            }
            statusMessage = "10 altın harcandı."
        }

        generatedChallenge = service.createChallenge(
            creatorName: creatorName,
            questionCount: questionCount,
            totalTime: totalTime,
            maxDifficulty: maxDifficulty,
            passLimit: passLimit,
            category: selectedCategory == "Karışık" ? nil : selectedCategory
        )
        scoreService.markPrivateRoomCreated(date: Date())
        roomCreationsToday = scoreService.privateRoomsCreatedToday(date: Date())
        roomAdWatchCount = 0
        errorMessage = nil
        withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
            isCreatorPanelExpanded = false
        }
    }

    private func watchRoomAd() {
        guard adService.isRewardedAdReady else {
            statusMessage = "Reklam hazır olduğunda bu buton aktifleşir."
            AdService.shared.refreshRewardedAd()
            return
        }
        isWatchingRoomAd = true
        AdService.shared.showRewardedAd {
            roomAdWatchCount = min(requiredRoomAds, roomAdWatchCount + 1)
            isWatchingRoomAd = false
            statusMessage = roomAdWatchCount >= requiredRoomAds ? "2 reklam tamamlandı. Şimdi oda oluşturabilirsin." : "1 reklam izlendi. Bir reklam daha gerekli."
        } onUnavailable: {
            isWatchingRoomAd = false
            statusMessage = "Reklam hazır değil. Biraz sonra tekrar dene."
        }
    }

    private var roomAdButtonTitle: String {
        if isWatchingRoomAd { return "Reklam Hazırlanıyor" }
        if !adService.isRewardedAdReady { return "Reklam Hazır Değil" }
        return "Reklam İzle (\(roomAdWatchCount)/\(requiredRoomAds))"
    }
}
