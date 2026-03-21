import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {

            Button { withAnimation { sidebarVisible.toggle() } } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)

            Text("Paradise IDE")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic().foregroundColor(t.accent)

            Button {
                folderManager.showPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder").font(.system(size: 11))
                    Text(folderManager.rootName).font(.system(size: 10, design: .monospaced)).lineLimit(1)
                }
                .foregroundColor(folderManager.rootURL != nil ? t.accent : t.mutedColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(folderManager.rootURL != nil ? t.accent.opacity(0.12) : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(folderManager.rootURL != nil ? t.accent : t.surfaceBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $folderManager.showPicker) {
                FolderPicker { url in
                    folderManager.openFolder(url)
                    folderManager.showPicker = false
                }
            }

            Spacer()

            // Theme dots
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

            // Perf
            Button { vm.performanceMode.toggle() } label: {
                Text("PERF")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(vm.performanceMode ? t.accent : t.mutedColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 20).fill(vm.performanceMode ? t.accent.opacity(0.15) : Color.clear).overlay(RoundedRectangle(cornerRadius: 20).stroke(vm.performanceMode ? t.accent : t.surfaceBorder, lineWidth: 1)))
            }.buttonStyle(.plain)

            // Terminal
            Button { withAnimation { terminalVisible.toggle() } } label: {
                Image(systemName: "terminal")
                    .font(.system(size: 13))
                    .foregroundColor(terminalVisible ? t.accent : t.mutedColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 20).fill(terminalVisible ? t.accent.opacity(0.15) : Color.clear).overlay(RoundedRectangle(cornerRadius: 20).stroke(terminalVisible ? t.accent : t.surfaceBorder, lineWidth: 1)))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(t.surface.background(.ultraThinMaterial).ignoresSafeArea(edges: .top))
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}
