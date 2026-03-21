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

            // AI response panel
            if vm.showAIPanel && !vm.aiResponse.isEmpty {
                AIResponsePanel()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            EditorToolbarView()
        }
        .background(Color.black.opacity(0.12))
        .animation(.spring(response: 0.3), value: vm.guideMode)
        .animation(.spring(response: 0.3), value: vm.showFindReplace)
        .animation(.spring(response: 0.3), value: vm.showAIPanel)
    }
}

// MARK: - Welcome screen (no tabs open)

struct WelcomeView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 20) {
            Text("Paradise IDE")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(t.accent)

            Text("Open a folder to start coding")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(t.mutedColor)

            HStack(spacing: 12) {
                Button("Open Folder") {
                    folderManager.showPicker = true
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.accent)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1))
                .buttonStyle(.plain)

                Button("New File") {
                    vm.newUntitledTab()
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                // New tab button
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
        .background(t.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
        .overlay(
            HStack {
                Spacer()
                // Guide + Pet
                HStack(spacing: 8) {
                    Button { withAnimation { vm.guideMode.toggle() } } label: {
                        Text("Guide")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(vm.guideMode ? t.accent : t.mutedColor)
                    }.buttonStyle(.plain)

                    // Save button
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
                    .fill(theme.accent)
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
        .background(t.accent.opacity(0.08))
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
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
        .background(Color.black.opacity(0.2))
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
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
        .background(Color.black.opacity(0.15))
        .overlay(Rectangle().frame(width: 1).foregroundColor(t.surfaceBorder), alignment: .trailing)
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
                        .background(RoundedRectangle(cornerRadius: 8).fill(t.accent.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1)))
                        .buttonStyle(.plain)
                }
                Button("Dismiss") { vm.dismissSuggestion() }
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.mutedColor)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
                    .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(t.surface).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14)).shadow(color: t.accent.opacity(0.2), radius: 16))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.accent.opacity(0.4), lineWidth: 1))
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
        .background(t.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .top)
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
            // AI Tools
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
                    .background(RoundedRectangle(cornerRadius: 8).fill(t.accent.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1)))
            }
            .buttonStyle(.plain)
            .shadow(color: vm.aiPulsing ? t.accent.opacity(0.7) : .clear, radius: vm.aiPulsing ? 12 : 0)

            // Find/Replace
            Button {
                withAnimation { vm.showFindReplace.toggle() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(vm.showFindReplace ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            // Save
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
                .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
            }.buttonStyle(.plain)

            // Export
            Button { vm.showExportPanel = true } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
            }.buttonStyle(.plain)

            Spacer()

            // Language indicator
            if let tab = vm.activeTab {
                Text(tab.language.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(t.mutedColor)
            }

            // Flow state dot
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
        .background(t.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .top)
    }
}
