import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }

            Text("Ayarlar")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                Toggle("Ses efektleri", isOn: $soundEnabled)
                Toggle("Titreşim", isOn: $hapticsEnabled)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .toggleStyle(SwitchToggleStyle(tint: GameTheme.yellow))
            .padding(16)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 16))

            Text("İlk MVP sürümünde ayarlar yerel olarak saklanır. Ses sistemi ileride özel efekt dosyalarıyla genişletilmeye hazırdır.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding(20)
    }
}
