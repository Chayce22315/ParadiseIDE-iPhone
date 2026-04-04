import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView()

            if vm.guideMode {
                GuideBannerView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if vm.showFindReplace {
                FindReplaceBar()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if vm.tabs.isEmpty {
                WelcomeView()
            } else {
                HStack(spacing: 0) {
                    LineGutter()
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

            VStack(spacing: 8) {
                Text(t.petEmoji)
                    .font(.system(size: 56))

                Text("Paradise IDE")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .italic()
                    .foregroundColor(t.accent)

                Text("Your tropical coding sanctuary")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(t.mutedColor)
            }

            VStack(spacing: 12) {
                WelcomeActionButton(
                    icon: "folder.badge.plus",
                    title: "Open Project",
                    subtitle: "Browse your files",
                    theme: t
                ) {
                    folderManager.showPicker = true
                }

                WelcomeActionButton(
                    icon: "doc.badge.plus",
                    title: "New File",
                    subtitle: "Start from scratch",
                    theme: t
                ) {
                    vm.newUntitledTab()
                }

                WelcomeActionButton(
                    icon: "keyboard",
                    title: "Quick Actions",
                    subtitle: "Shortcuts & tools",
                    theme: t
                ) {
                    // handled via top bar
                }
            }
            .frame(maxWidth: 280)

            Spacer()

            HStack(spacing: 16) {
                ForEach(["Lines: \(vm.lineCount)", vm.edition.rawValue, "v1.2.0"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(t.mutedColor.opacity(0.6))
                }
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.textColor)
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.mutedColor.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.surface.opacity(0.5))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), theme.surfaceBorder],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
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
        HStack(spacing: 0) {
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

            Spacer()

            HStack(spacing: 10) {
                Button { withAnimation { vm.guideMode.toggle() } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                        Text("Guide")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(vm.guideMode ? t.accent : t.mutedColor)
                }.buttonStyle(.plain)

                Button {
                    vm.saveActiveTab(using: folderManager)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 13))
                        .foregroundColor(vm.activeTab?.isDirty == true ? t.accent : t.mutedColor)
                }.buttonStyle(.plain)

                VirtualPetView()
            }
            .padding(.trailing, 12)
        }
        .frame(height: 40)
        .background(
            t.surface.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(t.surfaceBorder.opacity(0.5))
                .frame(height: 0.5),
            alignment: .bottom
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
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(isActive ? theme.accent : theme.mutedColor)
                .lineLimit(1)

            if tab.isDirty {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 6, height: 6)
            }

            Button {
                vm.closeTab(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.mutedColor.opacity(0.6))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? theme.accent.opacity(0.10) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? theme.accent.opacity(0.3) : Color.clear, lineWidth: 0.5)
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
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(t.accent)
                .font(.system(size: 13))
            Text("Guide Mode active -- AI highlights next steps as you type")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor)
            Spacer()
            Button { vm.guideMode = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(
            t.accent.opacity(0.06)
                .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Find / Replace bar

struct FindReplaceBar: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(t.mutedColor)
                .font(.system(size: 13))

            TextField("Find", text: $vm.findText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity)

            Image(systemName: "arrow.right")
                .foregroundColor(t.mutedColor)
                .font(.system(size: 11))

            TextField("Replace", text: $vm.replaceText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.textColor).tint(t.accent)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity)

            Button("Replace All") {
                if !vm.findText.isEmpty {
                    vm.code = vm.code.replacingOccurrences(of: vm.findText, with: vm.replaceText)
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(t.accent)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(t.accent.opacity(0.12)))
            .buttonStyle(.plain)

            Button { vm.showFindReplace = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.black.opacity(0.15).background(.ultraThinMaterial))
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(height: 0.5), alignment: .bottom)
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
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(n == vm.currentLine ? t.accent : t.mutedColor.opacity(0.4))
                        .frame(height: 22, alignment: .trailing)
                        .padding(.trailing, 10)
                }
            }.padding(.top, 14)
        }
        .background(Color.black.opacity(0.1))
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(width: 0.5), alignment: .trailing)
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
            .padding(.leading, 12).padding(.top, 10)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(t.accent)
                Text("AI CO-PILOT")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor)
            }

            Text(suggestion.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(t.textColor)
                .lineSpacing(3)

            HStack(spacing: 10) {
                if suggestion.fix != nil {
                    Button("Apply Fix") { vm.applyFix() }
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(t.accent.opacity(0.15))
                                .overlay(Capsule().stroke(t.accent.opacity(0.5), lineWidth: 0.5))
                        )
                        .buttonStyle(.plain)
                }
                Button("Dismiss") { vm.dismissSuggestion() }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .overlay(Capsule().stroke(t.surfaceBorder, lineWidth: 0.5))
                    )
                    .buttonStyle(.plain)
            }
        }
        .glassCard(theme: t, cornerRadius: 18, padding: 16)
        .frame(maxWidth: 320)
    }
}

// MARK: - AI Response panel

struct AIResponsePanel: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(t.accent)
                    Text("AI Response")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent)
                }
                Spacer()
                Button { vm.showAIPanel = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(t.mutedColor)
                }.buttonStyle(.plain)
            }

            ScrollView {
                Text(vm.aiResponse)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(t.textColor)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 160)
        }
        .padding(14)
        .background(
            t.surface.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [t.accent.opacity(0.3), t.accent.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Bottom toolbar

struct EditorToolbarView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 12) {
            // AI button
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
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("AI")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(t.accent)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(t.accent.opacity(0.12))
                        .overlay(Capsule().stroke(t.accent.opacity(0.3), lineWidth: 0.5))
                )
            }
            .buttonStyle(.plain)
            .shadow(color: vm.aiPulsing ? t.accent.opacity(0.7) : .clear, radius: vm.aiPulsing ? 12 : 0)

            Button {
                withAnimation { vm.showFindReplace.toggle() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(vm.showFindReplace ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            Button {
                vm.saveActiveTab(using: folderManager)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(vm.activeTab?.isDirty == true ? t.accent : t.mutedColor)
            }.buttonStyle(.plain)

            Button { vm.showExportPanel = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(t.mutedColor)
            }.buttonStyle(.plain)

            Spacer()

            if let tab = vm.activeTab {
                Text(tab.language.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(t.surface.opacity(0.5)))
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(t.accent)
                    .frame(width: 7, height: 7)
                    .shadow(color: t.accent.opacity(vm.performanceMode ? 0 : 0.8), radius: 5)
                Text("Flow")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(
            t.surface.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(t.surfaceBorder.opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
