import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @State private var sidebarVisible = false
    @State private var terminalVisible = false
    @State private var rightPanelVisible = false
    @State private var terminalHeight: CGFloat = 300
    @State private var showSnippets = false
    @State private var showQuickActions = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            let isLargeScreen = geo.size.width >= 420
            let sidebarWidth: CGFloat = isLargeScreen ? 260 : 220

            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.2), value: vm.theme.id)

                if !vm.performanceMode { ParticleLayerView().ignoresSafeArea() }

                VStack(spacing: 0) {
                    TopBarView(
                        sidebarVisible: $sidebarVisible,
                        terminalVisible: $terminalVisible,
                        rightPanelVisible: $rightPanelVisible,
                        showSnippets: $showSnippets,
                        showQuickActions: $showQuickActions
                    )

                    EditorView()

                    if terminalVisible {
                        VStack(spacing: 0) {
                            TerminalPanelHeader(
                                terminalHeight: $terminalHeight,
                                terminalVisible: $terminalVisible,
                                theme: t,
                                maxHeight: geo.size.height * 0.6
                            )
                            TerminalView()
                                .frame(height: min(terminalHeight, geo.size.height * 0.55))
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    StatusBarView()
                }

                // Sidebar overlay
                if sidebarVisible {
                    HStack(spacing: 0) {
                        FileTreeView()
                            .frame(width: sidebarWidth)
                            .background(
                                GlassBackground(theme: t, intensity: 0.9)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 5)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    sidebarVisible = false
                                }
                            }
                    }
                    .zIndex(5)
                }

                // Right panel overlay
                if rightPanelVisible {
                    HStack(spacing: 0) {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    rightPanelVisible = false
                                }
                            }

                        RightPanelView()
                            .frame(width: isLargeScreen ? 300 : 260)
                            .background(
                                GlassBackground(theme: t, intensity: 0.9)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: -5)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    .zIndex(5)
                }

                if vm.showErrorToast {
                    ErrorToastView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sidebarVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: rightPanelVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: terminalVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showErrorToast)
            .sheet(isPresented: $vm.showExportPanel) {
                ExportView().environmentObject(vm)
            }
            .sheet(isPresented: $showSnippets) {
                SnippetsView().environmentObject(vm)
            }
            .sheet(isPresented: $showQuickActions) {
                QuickActionsView().environmentObject(vm).environmentObject(folderManager)
            }
        }
    }
}

// MARK: - Liquid Glass Background

struct GlassBackground: View {
    let theme: ParadiseTheme
    var intensity: Double = 0.85

    var body: some View {
        ZStack {
            theme.surface.opacity(intensity)
            Color.white.opacity(0.03)
        }
        .background(.ultraThinMaterial)
    }
}

struct GlassCard: ViewModifier {
    let theme: ParadiseTheme
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.surface.opacity(0.6))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    theme.accent.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
            )
    }
}

extension View {
    func glassCard(theme: ParadiseTheme, cornerRadius: CGFloat = 16, padding: CGFloat = 14) -> some View {
        modifier(GlassCard(theme: theme, cornerRadius: cornerRadius, padding: padding))
    }
}

struct TerminalPanelHeader: View {
    @Binding var terminalHeight: CGFloat
    @Binding var terminalVisible: Bool
    let theme: ParadiseTheme
    var maxHeight: CGFloat = 560

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.mutedColor.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.leading, 16)

            Image(systemName: "terminal")
                .font(.system(size: 12))
                .foregroundColor(theme.mutedColor)

            Text("TERMINAL")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(theme.mutedColor)

            Spacer()

            ForEach([("S", 200.0), ("M", 320.0), ("L", 480.0)], id: \.0) { label, h in
                Button(label) {
                    withAnimation(.spring(response: 0.3)) { terminalHeight = h }
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(abs(terminalHeight - h) < 1 ? theme.accent : theme.mutedColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(abs(terminalHeight - h) < 1 ? theme.accent.opacity(0.15) : Color.clear)
                )
                .buttonStyle(.plain)
            }

            Button { withAnimation { terminalVisible = false } } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain).padding(.trailing, 16)
        }
        .frame(height: 36)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.accent.opacity(0.3), theme.accent.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
        .gesture(DragGesture().onChanged { value in
            let newHeight = terminalHeight - value.translation.height
            terminalHeight = max(160, min(maxHeight, newHeight))
        })
    }
}
