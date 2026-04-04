import SwiftUI

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let theme: ParadiseTheme
    let cornerRadius: CGFloat
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(isActive ? 0.15 : 0.05),
                                        Color.white.opacity(0.03),
                                        theme.accent.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        theme.accent.opacity(isActive ? 0.3 : 0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: theme.accent.opacity(isActive ? 0.15 : 0.05), radius: 12, y: 4)
            )
    }
}

extension View {
    func liquidGlass(theme: ParadiseTheme, cornerRadius: CGFloat = 16, isActive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(theme: theme, cornerRadius: cornerRadius, isActive: isActive))
    }

    func glassButton(theme: ParadiseTheme, isActive: Bool = false) -> some View {
        self
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay(
                        Capsule()
                            .fill(isActive ? theme.accent.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        isActive ? theme.accent.opacity(0.3) : Color.white.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 14) {
            if let tab = vm.activeTab {
                HStack(spacing: 5) {
                    Circle().fill(t.accent).frame(width: 5, height: 5)
                    Text(tab.name).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(t.mutedColor)
                }
                Text(tab.language.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(t.accent.opacity(0.7))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(t.accent.opacity(0.1)))
            }
            Text("Ln \(vm.lineCount)").font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
            Spacer()
            Text(t.petEmoji).font(.system(size: 12))
            Text("Paradise IDE").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(t.mutedColor.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .frame(height: 28)
        .background(.ultraThinMaterial.opacity(0.6))
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .top)
    }
}

// MARK: - Error Toast

struct ErrorToastView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(t.accent.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 18)).foregroundColor(t.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("PARADISE TOOLS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Text("No stress! The AI can help fix this.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(t.textColor)
                }
                Spacer()
                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(t.mutedColor)
                        .font(.system(size: 18))
                }.buttonStyle(.plain)
            }
            .padding(16)
            .liquidGlass(theme: t, cornerRadius: 18)
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
                    .font(.system(size: CGFloat(20 + (i % 3) * 10)))
                    .position(
                        x: geo.size.width * (0.10 + Double(i) * 0.18 + Double(i % 2) * 0.08),
                        y: geo.size.height * (0.05 + Double(i % 4) * 0.22)
                    )
                    .opacity(0.08 + Double(i % 3) * 0.03)
                    .blur(radius: 1)
                    .modifier(FloatModifier(delay: Double(i) * 0.7, range: 20))
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

// MARK: - Dynamic Island View

struct DynamicIslandView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    @State private var expanded = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    var sessionTimeFormatted: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    expanded.toggle()
                }
            } label: {
                if expanded {
                    expandedContent
                } else {
                    compactContent
                }
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedSeconds += 1
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    var compactContent: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.petMood == .typing ? Color.green : (vm.petMood == .ai ? t.accent : t.mutedColor.opacity(0.5)))
                    .frame(width: 7, height: 7)
                    .shadow(color: vm.petMood == .typing ? .green.opacity(0.8) : .clear, radius: 5)

                Text(vm.activeTab?.name ?? "Paradise IDE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(t.textColor)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                if vm.petMood == .typing {
                    Text("typing...")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                }

                Text(sessionTimeFormatted)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor)

                Text(t.petEmoji).font(.system(size: 13))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), t.accent.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 12, y: 4)
        )
    }

    var expandedContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text(t.petEmoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Paradise IDE")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(t.textColor)
                    Text(vm.petMood.message.isEmpty ? "Ready to code" : vm.petMood.message)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sessionTimeFormatted)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                    Text("session")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                }
            }

            Divider().background(t.surfaceBorder.opacity(0.3))

            HStack(spacing: 16) {
                IslandStatPill(icon: "doc.text", value: "\(vm.tabs.count)", label: "files", theme: t)
                IslandStatPill(icon: "text.alignleft", value: "\(vm.lineCount)", label: "lines", theme: t)
                IslandStatPill(icon: "character.cursor.ibeam", value: "\(vm.code.count)", label: "chars", theme: t)
                IslandStatPill(icon: "paintpalette", value: t.name, label: "theme", theme: t)
            }

            if let tab = vm.activeTab {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill").font(.system(size: 10)).foregroundColor(t.accent)
                    Text(tab.name)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(t.textColor)
                    Text(tab.language.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(t.accent.opacity(0.15)))
                    Spacer()
                    if tab.isDirty {
                        Text("unsaved")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 4)
            }

            HStack {
                Text(vm.edition.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                Spacer()
                Text(vm.edition.price)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [t.accent.opacity(0.08), Color.clear, t.accent.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), t.accent.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 20, y: 6)
        )
    }
}

struct IslandStatPill: View {
    let icon: String
    let value: String
    let label: String
    let theme: ParadiseTheme

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.accent)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textColor)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(theme.mutedColor)
        }
        .frame(maxWidth: .infinity)
    }
}
