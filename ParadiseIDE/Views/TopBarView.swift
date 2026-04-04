import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool
    @State private var showingPicker = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 12) {

            Button { withAnimation { sidebarVisible.toggle() } } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(sidebarVisible ? t.accent : t.mutedColor)
                    .padding(6)
                    .glassPill(color: t.accent, isActive: sidebarVisible)
            }.buttonStyle(.plain)

            Text("Paradise IDE")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .italic().foregroundColor(t.accent)

            Button { showingPicker = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "folder").font(.system(size: 11))
                    Text(folderManager.rootName)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                }
                .foregroundColor(folderManager.rootURL != nil ? t.accent : t.mutedColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .glassPill(color: t.accent, isActive: folderManager.rootURL != nil)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ParadiseTheme.all) { theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) { vm.theme = theme }
                        } label: {
                            Circle().fill(theme.accent).frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(vm.theme == theme ? .white.opacity(0.8) : Color.clear, lineWidth: 2)
                                        .padding(-3)
                                )
                                .shadow(color: vm.theme == theme ? theme.accent.opacity(0.6) : .clear, radius: 6)
                                .scaleEffect(vm.theme == theme ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3), value: vm.theme == theme)
                        }.buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 6) {
                Button { vm.performanceMode.toggle() } label: {
                    Image(systemName: vm.performanceMode ? "hare.fill" : "hare")
                        .font(.system(size: 12))
                        .foregroundColor(vm.performanceMode ? t.accent : t.mutedColor)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .glassPill(color: t.accent, isActive: vm.performanceMode)
                }.buttonStyle(.plain)

                Button { withAnimation { terminalVisible.toggle() } } label: {
                    Image(systemName: "terminal")
                        .font(.system(size: 13))
                        .foregroundColor(terminalVisible ? t.accent : t.mutedColor)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .glassPill(color: t.accent, isActive: terminalVisible)
                }.buttonStyle(.plain)

                Button { vm.showSettingsPanel = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(t.mutedColor)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .glassPill(color: t.accent)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .liquidGlassToolbar(theme: t)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}
