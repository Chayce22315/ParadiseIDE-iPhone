import SwiftUI

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 18) {
            Text("☮️ \(vm.edition.rawValue)")
            Text("🌴 \(t.name)")
            Text("Ln \(vm.lineCount)")
            Text("Col \(vm.column)")
            Text("\(t.petEmoji) Pet: Active")
            Text("✦ Flow State")
            Spacer()
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(t.mutedColor)
        .padding(.horizontal, 14)
        .frame(height: 26)
        .background(t.accent.opacity(0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(t.surfaceBorder),
            alignment: .top
        )
    }
}

// MARK: - Error Toast

struct ErrorToastView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Text("📩")
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 3) {
                    Text("PARADISE TOOLS")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                        .tracking(1)
                    Text("Hey! No stress — looks like a small typo. Try adding a semicolon? 🌴")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(t.textColor)
                        .lineSpacing(3)
                }

                Spacer()

                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(t.mutedColor)
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: 460)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(t.surface)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: t.accent.opacity(0.3), radius: 24, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(t.accent.opacity(0.4), lineWidth: 1)
            )
            .padding(.bottom, 36)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Particle Layer

struct ParticleLayerView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(t.particles.enumerated()), id: \.offset) { i, emoji in
                Text(emoji)
                    .font(.system(size: CGFloat(18 + (i % 3) * 8)))
                    .position(
                        x: geo.size.width * (0.10 + Double(i) * 0.18 + Double(i % 2) * 0.08),
                        y: geo.size.height * (0.05 + Double(i % 4) * 0.22)
                    )
                    .opacity(0.12 + Double(i % 3) * 0.05)
                    .blur(radius: 0.5)
                    .modifier(FloatModifier(delay: Double(i) * 0.7, range: 18))
            }
        }
        .animation(nil, value: vm.theme.id)
    }
}

// MARK: - Float animation modifier

struct FloatModifier: ViewModifier {
    let delay: Double
    let range: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3.5 + delay * 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = -range
                }
            }
    }
}
