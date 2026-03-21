import SwiftUI

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 16) {
            if let tab = vm.activeTab {
                Text(tab.name).font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
                Text(tab.language.uppercased()).font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
            }
            Text("Ln \(vm.lineCount)").font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
            Text(t.petEmoji)
            Spacer()
            Text("Paradise IDE").font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background(t.accent.opacity(0.10))
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .top)
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
                Image(systemName: "envelope").font(.system(size: 18)).foregroundColor(t.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PARADISE TOOLS").font(.system(size: 9, design: .monospaced)).foregroundColor(t.mutedColor)
                    Text("No stress! Looks like a small issue. The AI can help fix it.").font(.system(size: 12, design: .monospaced)).foregroundColor(t.textColor)
                }
                Spacer()
                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark").foregroundColor(t.mutedColor).font(.system(size: 12))
                }.buttonStyle(.plain)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(t.surface).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14)).shadow(color: t.accent.opacity(0.25), radius: 20))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.accent.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 16).padding(.bottom, 32)
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
