import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView()
            if vm.guideMode { GuideBannerView().transition(.move(edge: .top).combined(with: .opacity)) }
            if vm.showFindReplace { FindReplaceBar().transition(.move(edge: .top).combined(with: .opacity)) }

            if vm.tabs.isEmpty {
                WelcomeView()
            } else {
                HStack(spacing: 0) {
                    LineGutter()
                        .frame(width: 44)
                    CodeEditorPane()
                }
            }

            if vm.showAIPanel && !vm.aiResponse.isEmpty {
                AIResponsePanel()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            EditorToolbarView()
        }
        .background(Color.black.opacity(0.08))
        .animation(.spring(response: 0.3), value: vm.guideMode)
        .animation(.spring(response: 0.3), value: vm.showFindReplace)
        .animation(.spring(response: 0.3), value: vm.showAIPanel)
    }
}

// MARK: - Welcome screen

struct WelcomeView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 24) {
            ParadiseAppIcon(size: 80)
                .shadow(color: t.accent.opacity(0.3), radius: 20)

            Text("Paradise IDE")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(t.accent)

            Text("Open a folder or create a new file to start")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(t.mutedColor)

            HStack(spacing: 14) {
                Button("Open Folder") {
                    folderManager.showPicker = true
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.accent)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .liquidGlass(cornerRadius: 10, tint: t.accent, intensity: 0.8)
                .buttonStyle(.plain)

                Button("New File") {
                    vm.newUntitledTab()
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .liquidGlass(cornerRadius: 10, tint: t.mutedColor, intensity: 0.4)
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                Text("Quick Start")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor.opacity(0.6))

                HStack(spacing: 20) {
                    quickAction(icon: "swift", label: "Swift") { vm.newUntitledTab(language: "swift") }
                    quickAction(icon: "terminal.fill", label: "Python") { vm.newUntitledTab(language: "python") }
                    quickAction(icon: "j.square", label: "JS") { vm.newUntitledTab(language: "javascript") }
                    quickAction(icon: "globe", label: "HTML") { vm.newUntitledTab(language: "html") }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(t.accent.opacity(0.6))
                Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(t.mutedColor)
            }
            .frame(width: 52, height: 52)
            .liquidGlass(cornerRadius: 12, tint: t.accent, intensity: 0.3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab bar

struct TabBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(vm.tabs) { tab in
                    TabButton(tab: tab, theme: t)
                }

                Button {
                    vm.newUntitledTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(t.mutedColor)
                        .frame(width: 32, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 36)
        .background(.ultraThinMaterial.opacity(0.4))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .bottom)
        .overlay(
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Button { withAnimation { vm.guideMode.toggle() } } label: {
                        Text("Guide")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(vm.guideMode ? t.accent : t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        vm.saveActiveTab(using: folderManager)
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(vm.activeTab?.isDirty == true ? t.accent : t.mutedColor)
                    }.buttonStyle(.plain)

                    VirtualPetView()
                }
                .padding(.trailing, 10)
            }
        )
    }
}

struct TabButton: View {
    @EnvironmentObject var vm: EditorViewModel
    let tab: OpenTab
    let theme: ParadiseTheme

    var isActive: Bool { vm.activeTabID == tab.id }

    var body: some View {
        HStack(spacing: 5) {
            Text(tab.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isActive ? theme.accent : theme.mutedColor)
                .lineLimit(1)

            if tab.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
            }

            Button {
                vm.closeTab(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(isActive ? theme.accent.opacity(0.10) : Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundColor(isActive ? theme.accent : .clear),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture { vm.activeTabID = tab.id }
    }
}

// MARK: - Guide banner

struct GuideBannerView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "map").foregroundColor(t.accent).font(.system(size: 11))
            Text("Guide Mode: AI will highlight next steps as you type.")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(t.textColor)
            Spacer()
            Button { vm.guideMode = false } label: {
                Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(t.accent.opacity(0.06))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .bottom)
    }
}

// MARK: - Find / Replace bar

struct FindReplaceBar: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(t.mutedColor).font(.system(size: 11))

            TextField("Find", text: $vm.findText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(width: 120)

            Image(systemName: "arrow.right").foregroundColor(t.mutedColor).font(.system(size: 10))

            TextField("Replace", text: $vm.replaceText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(width: 120)

            Button("Replace All") {
                if !vm.findText.isEmpty {
                    vm.code = vm.code.replacingOccurrences(of: vm.findText, with: vm.replaceText)
                }
            }
            .font(.system(size: 10, design: .monospaced)).foregroundColor(t.accent)
            .buttonStyle(.plain)

            Spacer()

            Button { vm.showFindReplace = false } label: {
                Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.3))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .bottom)
    }
}

// MARK: - Line gutter

struct LineGutter: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(1, vm.lineCount), id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(n == vm.currentLine ? t.accent : t.mutedColor.opacity(0.5))
                        .frame(height: 20, alignment: .trailing)
                        .padding(.trailing, 8)
                }
            }.padding(.top, 14)
        }
        .background(Color.black.opacity(0.1))
        .overlay(
            Rectangle().frame(width: 0.5)
                .foregroundColor(t.surfaceBorder),
            alignment: .trailing
        )
        .disabled(true)
    }
}

// MARK: - Code editor pane

struct CodeEditorPane: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: Binding(
                get: { vm.code },
                set: { vm.code = $0 }
            ))
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(t.textColor)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(.leading, 10).padding(.top, 10)
            .tint(t.accent)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            if let suggestion = vm.currentSuggestion {
                AISuggestionPanel(suggestion: suggestion)
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - AI suggestion panel

struct AISuggestionPanel: View {
    @EnvironmentObject var vm: EditorViewModel
    let suggestion: AISuggestion
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI CO-PILOT", systemImage: "cpu")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(t.mutedColor)

            Text(suggestion.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor)

            HStack(spacing: 8) {
                if suggestion.fix != nil {
                    Button("Apply Fix") { vm.applyFix() }
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(t.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .liquidGlass(cornerRadius: 8, tint: t.accent, intensity: 0.8)
                        .buttonStyle(.plain)
                }
                Button("Dismiss") { vm.dismissSuggestion() }
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.mutedColor)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .liquidGlass(cornerRadius: 8, tint: t.mutedColor, intensity: 0.4)
                    .buttonStyle(.plain)
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 14, tint: t.accent, intensity: 0.9)
        .shadow(color: t.accent.opacity(0.2), radius: 16)
        .frame(maxWidth: 280)
    }
}

// MARK: - AI Response panel

struct AIResponsePanel: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Response", systemImage: "cpu")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent)
                Spacer()
                Button { vm.showAIPanel = false } label: {
                    Image(systemName: "xmark").font(.system(size: 11)).foregroundColor(t.mutedColor)
                }.buttonStyle(.plain)
            }

            ScrollView {
                Text(vm.aiResponse)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(t.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 140)
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.4))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .top)
    }
}

// MARK: - Bottom toolbar

struct EditorToolbarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Task {
                    let response = await aiService.complete(
                        prompt: "Review this code and give me the most important suggestion.",
                        context: vm.code
                    )
                    vm.aiResponse = response
                    vm.showAIPanel = true
                }
            } label: {
                Label("AI", systemImage: "cpu")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .liquidGlass(cornerRadius: 8, tint: t.accent, intensity: 0.6)
            }
            .buttonStyle(.plain)
            .shadow(color: vm.aiPulsing ? t.accent.opacity(0.7) : .clear, radius: vm.aiPulsing ? 12 : 0)

            Button {
                withAnimation { vm.showFindReplace.toggle() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(vm.showFindReplace ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            Button {
                vm.saveActiveTab(using: folderManager)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(vm.activeTab?.isDirty == true ? t.accent : t.mutedColor)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .liquidGlass(cornerRadius: 8, tint: t.mutedColor, intensity: 0.3)
            }.buttonStyle(.plain)

            Button { vm.showExportPanel = true } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .liquidGlass(cornerRadius: 8, tint: t.mutedColor, intensity: 0.3)
            }.buttonStyle(.plain)

            Spacer()

            if let tab = vm.activeTab {
                MiniTag(text: tab.language.uppercased(), color: t.accent)
            }

            HStack(spacing: 5) {
                Circle().fill(t.accent).frame(width: 6, height: 6)
                    .shadow(color: t.accent.opacity(0.8), radius: vm.performanceMode ? 0 : 5)
                Text("Flow")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(.ultraThinMaterial.opacity(0.4))
        .overlay(FrostedDivider(t.surfaceBorder), alignment: .top)
    }
}
