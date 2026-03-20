import SwiftUI

struct TopBarView: View {
@EnvironmentObject var vm: EditorViewModel
@EnvironmentObject var folderManager: FolderManager
@Binding var sidebarVisible: Bool
@Binding var terminalVisible: Bool
@State private var showFolderPicker = false

```
var t: ParadiseTheme { vm.theme }

var body: some View {
    HStack(spacing: 12) {
        // Sidebar toggle
        Button {
            withAnimation { sidebarVisible.toggle() }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(t.mutedColor)
        }
        .buttonStyle(.plain)

        // Logo
        HStack(spacing: 6) {
            Text("☮️")
                .font(.system(size: 16))
            Text("Paradise IDE")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(t.accent)
                .tracking(0.5)
        }

        // Current folder indicator
        Button {
            showFolderPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                Text(folderManager.currentFolderName)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(1)
            }
            .foregroundColor(folderManager.currentFolderURL != nil ? t.accent : t.mutedColor)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(folderManager.currentFolderURL != nil ? t.accent.opacity(0.12) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(folderManager.currentFolderURL != nil ? t.accent : t.surfaceBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                folderManager.setFolder(url)
                showFolderPicker = false
            }
        }

        Spacer()

        // Edition picker
        HStack(spacing: 4) {
            ForEach(IDEEdition.allCases, id: \.self) { ed in
                Button {
                    vm.edition = ed
                } label: {
                    Text(ed.rawValue + (ed == .enterprise ? " 💎" : ""))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(vm.edition == ed ? t.accent : t.mutedColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(vm.edition == ed ? t.accent.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(vm.edition == ed ? t.accent : t.surfaceBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }

        // Theme color dots
        HStack(spacing: 4) {
            Text("THEME")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .tracking(1)

            ForEach(ParadiseTheme.all) { theme in
                Button {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        vm.theme = theme
                    }
                } label: {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(vm.theme == theme ? theme.accent : Color.clear, lineWidth: 2)
                                .padding(-3)
                        )
                        .shadow(color: vm.theme == theme ? theme.accent.opacity(0.6) : .clear, radius: 6)
                        .scaleEffect(vm.theme == theme ? 1.25 : 1.0)
                        .animation(.spring(response: 0.3), value: vm.theme == theme)
                }
                .buttonStyle(.plain)
            }
        }

        // Perf mode
        Button {
            vm.performanceMode.toggle()
        } label: {
            Text("⚡ PERF")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(vm.performanceMode ? t.accent : t.mutedColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(vm.performanceMode ? t.accent.opacity(0.15) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(vm.performanceMode ? t.accent : t.surfaceBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

        // Terminal toggle
        Button {
            withAnimation { terminalVisible.toggle() }
        } label: {
            Text("🖥️ TERM")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(terminalVisible ? t.accent : t.mutedColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(terminalVisible ? t.accent.opacity(0.15) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(terminalVisible ? t.accent : t.surfaceBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    .padding(.horizontal, 14)
    .frame(height: 46)
    .background(
        t.surface
            .background(.ultraThinMaterial)
            .ignoresSafeArea(edges: .top)
    )
    .overlay(
        Rectangle()
            .frame(height: 1)
            .foregroundColor(t.surfaceBorder),
        alignment: .bottom
    )
}
```

}