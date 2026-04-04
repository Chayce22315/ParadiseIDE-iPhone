import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showDynamicIsland: Bool
    @State private var showingPicker = false
    @State private var showIconPreview = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {
            Button { withAnimation { sidebarVisible.toggle() } } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(sidebarVisible ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            Text("Paradise IDE")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic().foregroundColor(t.accent)

            Button { showingPicker = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder").font(.system(size: 11))
                    Text(folderManager.rootName)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                }
                .foregroundColor(folderManager.rootURL != nil ? t.accent : t.mutedColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .liquidGlass(
                    cornerRadius: 20,
                    tint: folderManager.rootURL != nil ? t.accent : t.mutedColor,
                    intensity: folderManager.rootURL != nil ? 0.8 : 0.3
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

            // Command palette button
            Button { withAnimation { showCommandPalette.toggle() } } label: {
                Image(systemName: "command")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(t.mutedColor)
                    .padding(6)
                    .liquidGlass(cornerRadius: 8, tint: t.accent, intensity: 0.3)
            }.buttonStyle(.plain)

            // App icon preview
            Button { showIconPreview = true } label: {
                ParadiseAppIcon(size: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }.buttonStyle(.plain)

            // Dynamic Island toggle
            Button { withAnimation { showDynamicIsland.toggle() } } label: {
                Image(systemName: showDynamicIsland ? "capsule.portrait.fill" : "capsule.portrait")
                    .font(.system(size: 12))
                    .foregroundColor(showDynamicIsland ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            // Theme switcher
            HStack(spacing: 6) {
                ForEach(ParadiseTheme.all) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.6)) { vm.theme = theme }
                    } label: {
                        Circle().fill(theme.accent).frame(width: 14, height: 14)
                            .overlay(Circle().stroke(vm.theme == theme ? theme.accent : Color.clear, lineWidth: 2).padding(-3))
                            .shadow(color: vm.theme == theme ? theme.accent.opacity(0.6) : .clear, radius: 5)
                            .scaleEffect(vm.theme == theme ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: vm.theme == theme)
                    }.buttonStyle(.plain)
                }
            }

            Button { vm.performanceMode.toggle() } label: {
                Text("PERF")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(vm.performanceMode ? t.accent : t.mutedColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .liquidGlass(
                        cornerRadius: 20,
                        tint: vm.performanceMode ? t.accent : t.mutedColor,
                        intensity: vm.performanceMode ? 0.8 : 0.3
                    )
            }.buttonStyle(.plain)

            Button { withAnimation { terminalVisible.toggle() } } label: {
                Image(systemName: "terminal")
                    .font(.system(size: 13))
                    .foregroundColor(terminalVisible ? t.accent : t.mutedColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .liquidGlass(
                        cornerRadius: 20,
                        tint: terminalVisible ? t.accent : t.mutedColor,
                        intensity: terminalVisible ? 0.8 : 0.3
                    )
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.ultraThinMaterial.opacity(0.8))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .bottom)
        .sheet(isPresented: $showIconPreview) {
            AppIconPreviewSheet().environmentObject(vm)
        }
    }
}
