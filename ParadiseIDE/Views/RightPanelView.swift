import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    @ObservedObject var liveActivity = LiveActivityManager.shared
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {

                CollapsibleSection(title: "AI CO-PILOT", icon: "cpu", theme: t) {
                    VStack(spacing: 5) {
                        AIActionButton(label: "Explain", icon: "text.magnifyingglass", theme: t) {
                            Task {
                                let r = await aiService.explainCode(vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Fix Bugs", icon: "wrench.and.screwdriver", theme: t) {
                            Task {
                                let r = await aiService.fixCode(vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Review", icon: "checkmark.seal", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Review this code for bugs, style, and improvements.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Comments", icon: "text.bubble", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Add inline documentation comments to this code. Return the full commented code.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                    }
                }

                CollapsibleSection(title: "FILE INFO", icon: "doc", theme: t) {
                    if let tab = vm.activeTab {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(t.accent).font(.system(size: 10))
                                Text(tab.name)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.accent).lineLimit(1)
                            }

                            HStack(spacing: 8) {
                                MiniTag(text: tab.language.uppercased(), color: t.accent)

                                if tab.isDirty {
                                    MiniTag(text: "UNSAVED", color: .orange)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(cornerRadius: 10, tint: t.accent, intensity: 0.5)
                    } else {
                        Text("No file open")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                }

                CollapsibleSection(title: "STATS", icon: "chart.bar", theme: t) {
                    VStack(alignment: .leading, spacing: 5) {
                        StatRow(label: "Lines",  value: "\(vm.lineCount)", theme: t)
                        StatRow(label: "Chars",  value: "\(vm.code.count)", theme: t)
                        StatRow(label: "Tabs",   value: "\(vm.tabs.count)", theme: t)
                        StatRow(label: "Theme",  value: t.name, theme: t)
                    }
                }

                CollapsibleSection(title: "SESSION", icon: "clock", theme: t) {
                    VStack(alignment: .leading, spacing: 5) {
                        StatRow(label: "Time", value: sessionTimer, theme: t)
                        StatRow(label: "Status", value: liveActivity.isActivityActive ? "Active" : "Idle", theme: t)
                    }
                }

                CollapsibleSection(title: "QUICK SNIPPETS", icon: "text.word.spacing", theme: t, startCollapsed: true) {
                    VStack(spacing: 4) {
                        SnippetButton(label: "Swift Struct", theme: t) {
                            insertSnippet("struct MyStruct {\n    \n}\n")
                        }
                        SnippetButton(label: "Swift Func", theme: t) {
                            insertSnippet("func myFunction() {\n    \n}\n")
                        }
                        SnippetButton(label: "SwiftUI View", theme: t) {
                            insertSnippet("struct MyView: View {\n    var body: some View {\n        Text(\"Hello\")\n    }\n}\n")
                        }
                        SnippetButton(label: "Python Func", theme: t) {
                            insertSnippet("def my_function():\n    pass\n")
                        }
                        SnippetButton(label: "JS Arrow Fn", theme: t) {
                            insertSnippet("const myFunc = () => {\n  \n};\n")
                        }
                    }
                }

                CollapsibleSection(title: "EXPORTS", icon: "square.and.arrow.up", theme: t, startCollapsed: true) {
                    VStack(spacing: 4) {
                        let docs = folderManager.listDocuments()
                        if docs.isEmpty {
                            Text("No exports yet")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        } else {
                            ForEach(docs, id: \.path) { url in
                                HStack {
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.textColor).lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .liquidGlass(cornerRadius: 6, tint: t.mutedColor, intensity: 0.3)
                            }
                        }
                    }
                }

                CollapsibleSection(title: "EDITION", icon: "star", theme: t, startCollapsed: true) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.edition.rawValue)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(t.accent)
                        Text(vm.edition.price)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(cornerRadius: 10, tint: t.accent, intensity: 0.5)
                }
            }
            .padding(10)
        }
        .background(.ultraThinMaterial.opacity(0.3))
        .overlay(
            Rectangle().frame(width: 0.5)
                .foregroundColor(t.surfaceBorder),
            alignment: .leading
        )
    }

    private var sessionTimer: String {
        let s = liveActivity.codingSeconds
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }

    private func insertSnippet(_ snippet: String) {
        if vm.tabs.isEmpty { vm.newUntitledTab() }
        vm.code = vm.code + "\n" + snippet
    }
}

// MARK: - Collapsible Section

struct CollapsibleSection<Content: View>: View {
    @EnvironmentObject var vm: EditorViewModel
    let title: String
    let icon: String
    let theme: ParadiseTheme
    let startCollapsed: Bool
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(
        title: String,
        icon: String,
        theme: ParadiseTheme,
        startCollapsed: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.theme = theme
        self.startCollapsed = startCollapsed
        self.content = content
        self._isExpanded = State(initialValue: !startCollapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 9))
                        .foregroundColor(theme.accent.opacity(0.7))

                    Text(title)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                        .tracking(1.2)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(theme.mutedColor.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)

            if isExpanded {
                content()
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Mini Tag

struct MiniTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.15)))
    }
}

// MARK: - Snippet Button

struct SnippetButton: View {
    let label: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 10))
                    .foregroundColor(theme.accent.opacity(0.7))
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 8))
                    .foregroundColor(theme.mutedColor)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .liquidGlass(cornerRadius: 6, tint: theme.accent, intensity: 0.3)
        }
        .buttonStyle(.plain)
    }
}

struct AIActionButton: View {
    let label: String
    let icon: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(theme.accent)
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(theme.mutedColor)
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .liquidGlass(cornerRadius: 8, tint: theme.accent, intensity: 0.3)
        }
        .buttonStyle(.plain)
    }
}

struct PanelSection<Content: View>: View {
    @EnvironmentObject var vm: EditorViewModel
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(vm.theme.mutedColor)
                .tracking(1.5)
            content()
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let theme: ParadiseTheme
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.mutedColor)
            Spacer()
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.accent)
        }
    }
}
