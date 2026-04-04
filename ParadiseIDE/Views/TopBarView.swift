import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool
    @Binding var rightPanelVisible: Bool
    @State private var showingPicker = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 12) {
            Button { withAnimation(.spring(response: 0.3)) { sidebarVisible.toggle() } } label: {
                Image(systemName: sidebarVisible ? "sidebar.left" : "line.3.horizontal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(sidebarVisible ? t.accent : t.mutedColor)
                    .glassButton(theme: t, isActive: sidebarVisible)
            }.buttonStyle(.plain)

            Button { showingPicker = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "folder.fill").font(.system(size: 11))
                    Text(folderManager.rootName)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                }
                .foregroundColor(folderManager.rootURL != nil ? t.accent : t.mutedColor)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(folderManager.rootURL != nil ? t.accent.opacity(0.12) : Color.clear)
                        .overlay(Capsule().stroke(folderManager.rootURL != nil ? t.accent.opacity(0.3) : t.surfaceBorder, lineWidth: 0.5))
                )
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showingPicker) {
                FolderPicker(
                    onPick: { url in
                        showingPicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            folderManager.openFolder(url)
                        }
                    },
                    onCancel: { showingPicker = false }
                )
                .ignoresSafeArea()
            }

            Spacer()

            HStack(spacing: 5) {
                ForEach(ParadiseTheme.all) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.6)) { vm.theme = theme }
                    } label: {
                        Circle().fill(theme.accent).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(vm.theme == theme ? .white.opacity(0.8) : Color.clear, lineWidth: 1.5).padding(-2))
                            .shadow(color: vm.theme == theme ? theme.accent.opacity(0.8) : .clear, radius: 6)
                            .scaleEffect(vm.theme == theme ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: vm.theme == theme)
                    }.buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                ToolbarPillButton(icon: "gearshape", label: nil, isActive: false, theme: t) {
                    vm.showSettingsPanel = true
                }

                ToolbarPillButton(icon: "doc.on.clipboard", label: nil, isActive: false, theme: t) {
                    vm.showSnippetsPanel = true
                }

                ToolbarPillButton(icon: "terminal", label: nil, isActive: terminalVisible, theme: t) {
                    withAnimation { terminalVisible.toggle() }
                }

                ToolbarPillButton(icon: "sidebar.right", label: nil, isActive: rightPanelVisible, theme: t) {
                    withAnimation(.spring(response: 0.3)) { rightPanelVisible.toggle() }
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.ultraThinMaterial.opacity(0.8))
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}

struct ToolbarPillButton: View {
    let icon: String
    let label: String?
    let isActive: Bool
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                if let label = label {
                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }
            .foregroundColor(isActive ? theme.accent : theme.mutedColor)
            .glassButton(theme: theme, isActive: isActive)
        }
        .buttonStyle(.plain)
    }
}
