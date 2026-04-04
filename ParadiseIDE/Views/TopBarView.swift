import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool
    @Binding var rightPanelVisible: Bool
    @Binding var showSnippets: Bool
    @Binding var showQuickActions: Bool
    @State private var showingPicker = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 0) {
            // Left group
            HStack(spacing: 14) {
                Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { sidebarVisible.toggle() } } label: {
                    Image(systemName: sidebarVisible ? "sidebar.left" : "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(sidebarVisible ? t.accent : t.mutedColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Paradise IDE")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundColor(t.accent)

                    if let tab = vm.activeTab {
                        Text(tab.name)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Center - Theme swatches
            HStack(spacing: 8) {
                ForEach(ParadiseTheme.all) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.6)) { vm.theme = theme }
                    } label: {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(vm.theme == theme ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
                                    .padding(-2)
                            )
                            .shadow(color: vm.theme == theme ? theme.accent.opacity(0.6) : .clear, radius: 6)
                            .scaleEffect(vm.theme == theme ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: vm.theme == theme)
                    }.buttonStyle(.plain)
                }
            }

            Spacer()

            // Right group
            HStack(spacing: 10) {
                TopBarButton(icon: "text.snippet", isActive: false, theme: t) {
                    showSnippets = true
                }

                TopBarButton(icon: "bolt.fill", isActive: false, theme: t) {
                    showQuickActions = true
                }

                TopBarButton(icon: "terminal", isActive: terminalVisible, theme: t) {
                    withAnimation { terminalVisible.toggle() }
                }

                TopBarButton(icon: "sidebar.right", isActive: rightPanelVisible, theme: t) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { rightPanelVisible.toggle() }
                }

                Button { vm.performanceMode.toggle() } label: {
                    Image(systemName: vm.performanceMode ? "hare.fill" : "tortoise.fill")
                        .font(.system(size: 13))
                        .foregroundColor(vm.performanceMode ? t.accent : t.mutedColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            ZStack {
                t.surface.opacity(0.7)
                    .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [t.accent.opacity(0.2), t.accent.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct TopBarButton: View {
    let icon: String
    let isActive: Bool
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? theme.accent : theme.mutedColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isActive ? theme.accent.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
