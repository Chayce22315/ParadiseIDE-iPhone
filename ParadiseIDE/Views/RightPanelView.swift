import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @ObservedObject private var aiService = AIService.shared
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {

                PanelSection(title: "AI CO-PILOT") {
                    VStack(spacing: 8) {
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
                        AIActionButton(label: "Comment", icon: "text.bubble", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Add inline documentation comments to this code. Return the full commented code.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Optimize", icon: "bolt.fill", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Optimize this code for performance. Explain what you changed and why.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                    }
                }

                PanelSection(title: "CURRENT FILE") {
                    if let tab = vm.activeTab {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(t.accent).font(.system(size: 11))
                                Text(tab.name)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(t.accent).lineLimit(1)
                            }
                            HStack(spacing: 8) {
                                Text(tab.language.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(t.accent)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(t.accent.opacity(0.15)))

                                if tab.isDirty {
                                    Text("Modified")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlassCard(theme: t, cornerRadius: 10)
                    } else {
                        Text("No file open")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                }

                PanelSection(title: "STATS") {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Lines",  value: "\(vm.lineCount)", theme: t)
                        StatRow(label: "Chars",  value: "\(vm.code.count)", theme: t)
                        StatRow(label: "Words",  value: "\(vm.wordCount)", theme: t)
                        StatRow(label: "Tabs",   value: "\(vm.tabs.count)", theme: t)
                        StatRow(label: "Theme",  value: t.name, theme: t)
                    }
                    .padding(10)
                    .liquidGlassCard(theme: t, cornerRadius: 10)
                }

                PanelSection(title: "TOOLS") {
                    VStack(spacing: 6) {
                        ToolButton(icon: "doc.on.clipboard", label: "Snippets", theme: t) {
                            vm.showSnippetsPanel = true
                        }
                        ToolButton(icon: "paintbrush", label: "Themes", theme: t) {
                            vm.showSettingsPanel = true
                        }
                        ToolButton(icon: "arrow.triangle.branch", label: "Git Status", theme: t) {
                            vm.aiResponse = "Git integration coming soon! Connect to a remote terminal to use git commands."
                            vm.showAIPanel = true
                        }
                    }
                }

                PanelSection(title: "EDITION") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.edition.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(t.accent)
                        Text(vm.edition.price)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlassCard(theme: t, cornerRadius: 10)
                }
            }
            .padding(14)
        }
        .background(
            ZStack {
                t.surface
                Color.black.opacity(0.05)
            }
            .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().frame(width: 0.5).foregroundColor(t.surfaceBorder), alignment: .leading)
    }
}

struct ToolButton: View {
    let icon: String
    let label: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.accent)
                Text(label).font(.system(size: 11, design: .monospaced)).foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(theme.mutedColor.opacity(0.5))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .liquidGlassCard(theme: theme, cornerRadius: 8)
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
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.accent)
                Text(label).font(.system(size: 11, design: .monospaced)).foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(theme.mutedColor.opacity(0.5))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .liquidGlassCard(theme: theme, cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
}

struct PanelSection<Content: View>: View {
    @EnvironmentObject var vm: EditorViewModel
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
            Text(label).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.mutedColor)
            Spacer()
            Text(value).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(theme.accent)
        }
    }
}
