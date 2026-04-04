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
                    MiniMapGutter()
                        .frame(width: 48)
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
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text(t.petEmoji)
                    .font(.system(size: 48))

                Text("Paradise IDE")
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(t.accent)

                Text("Open a folder or create a new file to begin")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(t.mutedColor)
            }

            HStack(spacing: 16) {
                Button("Open Folder") {
                    folderManager.showPicker = true
                }
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(
                    Capsule().fill(t.accent.opacity(0.3))
                        .background(.ultraThinMaterial, in: Capsule())
                )
                .overlay(Capsule().stroke(t.accent.opacity(0.5), lineWidth: 1))
                .buttonStyle(.plain)

                Button("New File") {
                    vm.newUntitledTab()
                }
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.white.opacity(0.05))
                        .background(.ultraThinMaterial, in: Capsule())
                )
                .overlay(Capsule().stroke(t.surfaceBorder, lineWidth: 1))
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                Text("QUICK START")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .tracking(2)

                HStack(spacing: 12) {
                    QuickActionCard(icon: "swift", title: "Swift", theme: t) {
                        vm.newUntitledTab(language: "swift")
                    }
                    QuickActionCard(icon: "terminal.fill", title: "Python", theme: t) {
                        vm.newUntitledTab(language: "python")
                    }
                    QuickActionCard(icon: "j.square.fill", title: "JavaScript", theme: t) {
                        vm.newUntitledTab(language: "javascript")
                    }
                    QuickActionCard(icon: "curlybraces", title: "JSON", theme: t) {
                        vm.newUntitledTab(language: "json")
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.accent)
                Text(title)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(theme.textColor)
            }
            .frame(width: 64, height: 64)
            .liquidGlassCard(theme: theme, cornerRadius: 12)
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
            HStack(spacing: 2) {
                ForEach(vm.tabs) { tab in
                    TabButton(tab: tab, theme: t)
                }

                Button {
                    vm.newUntitledTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(t.mutedColor)
                        .frame(width: 34, height: 38)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 38)
        .liquidGlassToolbar(theme: t)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .bottom)
        .overlay(
            HStack(spacing: 8) {
                Spacer()

                Button { withAnimation { vm.guideMode.toggle() } } label: {
                    Text("Guide")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(vm.guideMode ? t.accent : t.mutedColor)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .glassPill(color: t.accent, isActive: vm.guideMode)
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
        )
    }
}

struct TabButton: View {
    @EnvironmentObject var vm: EditorViewModel
    let tab: OpenTab
    let theme: ParadiseTheme

    var isActive: Bool { vm.activeTabID == tab.id }

    var body: some View {
        HStack(spacing: 6) {
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
                    .foregroundColor(theme.mutedColor.opacity(0.6))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? theme.accent.opacity(0.12) : Color.clear)
                .background(isActive ? .ultraThinMaterial : .bar, in: RoundedRectangle(cornerRadius: 8))
                .opacity(isActive ? 1 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? theme.accent.opacity(0.2) : .clear, lineWidth: 0.5)
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
            Text("Guide Mode — AI highlights next steps as you type")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(t.textColor)
            Spacer()
            Button { vm.guideMode = false } label: {
                Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(t.accent.opacity(0.06))
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}

// MARK: - Find / Replace bar

struct FindReplaceBar: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(t.mutedColor).font(.system(size: 12))

            TextField("Find", text: $vm.findText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(width: 130)

            Image(systemName: "arrow.right").foregroundColor(t.mutedColor).font(.system(size: 10))

            TextField("Replace", text: $vm.replaceText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(width: 130)

            Button("Replace All") {
                if !vm.findText.isEmpty {
                    vm.code = vm.code.replacingOccurrences(of: vm.findText, with: vm.replaceText)
                }
            }
            .font(.system(size: 11, design: .monospaced)).foregroundColor(t.accent)
            .buttonStyle(.plain)

            Spacer()

            Button { vm.showFindReplace = false } label: {
                Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.black.opacity(0.15))
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}

// MARK: - Mini-map / Line gutter (combined)

struct MiniMapGutter: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(1, vm.lineCount), id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(n == vm.currentLine ? t.accent : t.mutedColor.opacity(0.4))
                        .frame(height: 20, alignment: .trailing)
                        .padding(.trailing, 8)
                        .background(
                            n == vm.currentLine
                            ? t.accent.opacity(0.06)
                            : Color.clear
                        )
                }
            }.padding(.top, 14)
        }
        .background(Color.black.opacity(0.1))
        .overlay(Rectangle().frame(width: 0.5).foregroundColor(t.surfaceBorder), alignment: .trailing)
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
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(t.textColor)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(.leading, 12).padding(.top, 12)
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
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .tracking(1)

            Text(suggestion.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor)

            HStack(spacing: 8) {
                if suggestion.fix != nil {
                    Button("Apply Fix") { vm.applyFix() }
                        .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(t.accent.opacity(0.3)))
                        .overlay(Capsule().stroke(t.accent, lineWidth: 1))
                        .buttonStyle(.plain)
                }
                Button("Dismiss") { vm.dismissSuggestion() }
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.mutedColor)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .overlay(Capsule().stroke(t.surfaceBorder, lineWidth: 1))
                    .buttonStyle(.plain)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16, tint: t.accent, intensity: 1.5, borderOpacity: 0.3)
        .shadow(color: t.accent.opacity(0.15), radius: 20)
        .frame(maxWidth: 300)
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
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(t.accent)
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = vm.aiResponse
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .buttonStyle(.plain)

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
            .frame(maxHeight: 160)
        }
        .padding(14)
        .liquidGlassToolbar(theme: t)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .top)
    }
}

// MARK: - Bottom toolbar

struct EditorToolbarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @EnvironmentObject var github: GitHubService
    @StateObject private var aiService = AIService()
    @State private var showCommitAlert = false
    @State private var commitMessage = ""
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
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .glassPill(color: t.accent, isActive: true)
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
                .padding(.horizontal, 10).padding(.vertical, 7)
                .glassPill(color: t.accent, isActive: vm.activeTab?.isDirty == true)
            }.buttonStyle(.plain)

            Button { vm.showExportPanel = true } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .glassPill(color: t.accent)
            }.buttonStyle(.plain)

            Button { vm.showSnippetsPanel = true } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 13))
                    .foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)

            if github.isSignedIn && vm.activeTab != nil {
                Button { showCommitAlert = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Push")
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .glassPill(color: .green, isActive: true)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let tab = vm.activeTab {
                Text(tab.language.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(t.accent.opacity(0.12)))
            }

            HStack(spacing: 5) {
                Circle().fill(t.accent).frame(width: 6, height: 6)
                    .shadow(color: t.accent.opacity(0.8), radius: vm.performanceMode ? 0 : 5)
                Text("Flow")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .liquidGlassToolbar(theme: t)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .top)
        .alert("Commit & Push", isPresented: $showCommitAlert) {
            TextField("Commit message", text: $commitMessage)
            Button("Push") {
                let msg = commitMessage.isEmpty ? "Update \(vm.activeTab?.name ?? "file")" : commitMessage
                if let tab = vm.activeTab {
                    Task {
                        let success = await github.commitAndPush(
                            fileName: tab.name,
                            content: vm.code,
                            message: msg
                        )
                        if success {
                            vm.aiResponse = github.lastPushMessage ?? "Pushed successfully!"
                            vm.showAIPanel = true
                        } else {
                            vm.aiResponse = github.errorMessage ?? "Push failed"
                            vm.showAIPanel = true
                        }
                    }
                }
                commitMessage = ""
            }
            Button("Cancel", role: .cancel) { commitMessage = "" }
        } message: {
            Text("Push '\(vm.activeTab?.name ?? "file")' to \(github.selectedRepo?.name ?? "repo")")
        }
    }
}
