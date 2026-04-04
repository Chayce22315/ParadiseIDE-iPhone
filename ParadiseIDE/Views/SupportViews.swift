import SwiftUI

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @ObservedObject var liveActivity = LiveActivityManager.shared
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 12) {
            if let tab = vm.activeTab {
                HStack(spacing: 4) {
                    Circle()
                        .fill(tab.isDirty ? Color.orange : t.accent)
                        .frame(width: 5, height: 5)
                    Text(tab.name)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                        .lineLimit(1)
                }

                Text(tab.language.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(t.mutedColor.opacity(0.7))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(t.mutedColor.opacity(0.1)))
            }

            Text("Ln \(vm.lineCount)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(t.mutedColor)

            Text(t.petEmoji)

            Spacer()

            if liveActivity.isActivityActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(t.accent)
                        .frame(width: 4, height: 4)
                        .shadow(color: t.accent, radius: 3)
                    Text(sessionTimer)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(t.accent)
                }
            }

            Text("Paradise IDE")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(t.mutedColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 26)
        .background(.ultraThinMaterial.opacity(0.5))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .top)
    }

    private var sessionTimer: String {
        let s = liveActivity.codingSeconds
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
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
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(t.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PARADISE TOOLS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Text("No stress! Looks like a small issue. The AI can help fix it.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(t.textColor)
                }
                Spacer()
                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(t.mutedColor)
                        .font(.system(size: 12))
                }.buttonStyle(.plain)
            }
            .padding(16)
            .liquidGlass(cornerRadius: 18, tint: t.accent, intensity: 0.9)
            .shadow(color: t.accent.opacity(0.25), radius: 20)
            .padding(.horizontal, 16).padding(.bottom, 36)
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
                    .opacity(0.10 + Double(i % 3) * 0.04)
                    .blur(radius: 0.5)
                    .modifier(FloatModifier(delay: Double(i) * 0.7, range: 18))
            }
        }
    }
}

struct FloatModifier: ViewModifier {
    let delay: Double
    let range: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content.offset(y: offset).onAppear {
            withAnimation(.easeInOut(duration: 3.5 + delay * 0.4).repeatForever(autoreverses: true).delay(delay)) {
                offset = -range
            }
        }
    }
}
