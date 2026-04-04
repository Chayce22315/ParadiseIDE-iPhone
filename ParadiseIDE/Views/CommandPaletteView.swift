import SwiftUI

// MARK: - Command Palette

struct CommandPaletteView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @Binding var isPresented: Bool
    @Binding var sidebarVisible: Bool
    @Binding var terminalVisible: Bool

    @State private var query = ""
    @FocusState private var isFocused: Bool

    var t: ParadiseTheme { vm.theme }

    private var commands: [PaletteCommand] {
        [
            PaletteCommand(icon: "doc.badge.plus", label: "New File", shortcut: "N") {
                vm.newUntitledTab()
                isPresented = false
            },
            PaletteCommand(icon: "folder", label: "Open Folder", shortcut: "O") {
                folderManager.showPicker = true
                isPresented = false
            },
            PaletteCommand(icon: "square.and.arrow.down", label: "Save File", shortcut: "S") {
                vm.saveActiveTab(using: folderManager)
                isPresented = false
            },
            PaletteCommand(icon: "magnifyingglass", label: "Find & Replace", shortcut: "F") {
                vm.showFindReplace = true
                isPresented = false
            },
            PaletteCommand(icon: "terminal", label: "Toggle Terminal", shortcut: "T") {
                withAnimation { terminalVisible.toggle() }
                isPresented = false
            },
            PaletteCommand(icon: "sidebar.left", label: "Toggle Sidebar", shortcut: "B") {
                withAnimation { sidebarVisible.toggle() }
                isPresented = false
            },
            PaletteCommand(icon: "paintpalette", label: "Next Theme", shortcut: "K") {
                cycleTheme()
                isPresented = false
            },
            PaletteCommand(icon: "cpu", label: "AI: Explain Code", shortcut: nil) {
                vm.showAIPanel = true
                isPresented = false
            },
            PaletteCommand(icon: "square.and.arrow.up", label: "Export Project", shortcut: "E") {
                vm.showExportPanel = true
                isPresented = false
            },
            PaletteCommand(icon: "bolt", label: "Toggle Performance Mode", shortcut: "P") {
                vm.performanceMode.toggle()
                isPresented = false
            },
            PaletteCommand(icon: "map", label: "Toggle Guide Mode", shortcut: "G") {
                vm.guideMode.toggle()
                isPresented = false
            },
            PaletteCommand(icon: "arrow.clockwise", label: "Refresh File Tree", shortcut: "R") {
                folderManager.refresh()
                isPresented = false
            },
            PaletteCommand(icon: "text.word.spacing", label: "Insert Snippet: Swift Struct", shortcut: nil) {
                insertSnippet("struct MyStruct {\n    \n}\n")
                isPresented = false
            },
            PaletteCommand(icon: "text.word.spacing", label: "Insert Snippet: Swift Function", shortcut: nil) {
                insertSnippet("func myFunction() {\n    \n}\n")
                isPresented = false
            },
            PaletteCommand(icon: "text.word.spacing", label: "Insert Snippet: SwiftUI View", shortcut: nil) {
                insertSnippet("struct MyView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}\n")
                isPresented = false
            },
            PaletteCommand(icon: "text.word.spacing", label: "Insert Snippet: Python Function", shortcut: nil) {
                insertSnippet("def my_function():\n    pass\n")
                isPresented = false
            },
        ]
    }

    private var filteredCommands: [PaletteCommand] {
        if query.isEmpty { return commands }
        let q = query.lowercased()
        return commands.filter { $0.label.lowercased().contains(q) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "command")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(t.accent)

                    TextField("Type a command...", text: $query)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(t.textColor)
                        .tint(t.accent)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            if let first = filteredCommands.first {
                                first.action()
                            }
                        }

                    Button { isPresented = false } label: {
                        Text("ESC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(t.mutedColor.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                FrostedDivider(t.surfaceBorder)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredCommands) { cmd in
                            Button { cmd.action() } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: cmd.icon)
                                        .font(.system(size: 13))
                                        .foregroundColor(t.accent)
                                        .frame(width: 22)

                                    Text(cmd.label)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)

                                    Spacer()

                                    if let sc = cmd.shortcut {
                                        Text("^\(sc)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(t.mutedColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(t.mutedColor.opacity(0.1)))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 340)
            }
            .liquidGlass(cornerRadius: 20, tint: t.accent, intensity: 0.8)
            .padding(.horizontal, 24)
            .padding(.top, 80)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear { isFocused = true }
    }

    private func cycleTheme() {
        let themes = ParadiseTheme.all
        let idx = themes.firstIndex(where: { $0.id == vm.theme.id }) ?? 0
        let next = (idx + 1) % themes.count
        withAnimation(.easeInOut(duration: 0.6)) { vm.theme = themes[next] }
    }

    private func insertSnippet(_ snippet: String) {
        if vm.tabs.isEmpty { vm.newUntitledTab() }
        vm.code = vm.code + "\n" + snippet
    }
}

// MARK: - Palette Command

struct PaletteCommand: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let shortcut: String?
    let action: () -> Void
}
