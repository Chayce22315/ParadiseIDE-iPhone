import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // AI Co-pilot section
                CollapsibleSection(title: "AI CO-PILOT", icon: "sparkles", theme: t) {
                    VStack(spacing: 8) {
                        AIActionButton(label: "Explain Code", icon: "text.magnifyingglass", theme: t) {
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
                        AIActionButton(label: "Document", icon: "text.bubble", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Add inline documentation comments to this code. Return the full commented code.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Optimize", icon: "gauge.with.dots.needle.67percent", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Optimize this code for performance. Return the improved code with explanations.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                    }
                }

                // Current file section
                CollapsibleSection(title: "CURRENT FILE", icon: "doc.text", theme: t) {
                    if let tab = vm.activeTab {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(t.accent)
                                    .font(.system(size: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tab.name)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(t.accent)
                                        .lineLimit(1)
                                    Text(tab.language.uppercased())
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            if tab.isDirty {
                                HStack(spacing: 4) {
                                    Circle().fill(.orange).frame(width: 5, height: 5)
                                    Text("Unsaved changes")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(t.accent.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.surfaceBorder.opacity(0.5), lineWidth: 0.5))
                        )
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.badge.ellipsis")
                                .foregroundColor(t.mutedColor)
                            Text("No file open")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }
                        .padding(10)
                    }
                }

                // Stats section
                CollapsibleSection(title: "STATS", icon: "chart.bar", theme: t) {
                    VStack(spacing: 6) {
                        StatRow(label: "Lines", value: "\(vm.lineCount)", icon: "text.alignleft", theme: t)
                        StatRow(label: "Chars", value: "\(vm.code.count)", icon: "character.cursor.ibeam", theme: t)
                        StatRow(label: "Words", value: "\(vm.code.split(separator: " ").count)", icon: "textformat.abc", theme: t)
                        StatRow(label: "Tabs", value: "\(vm.tabs.count)", icon: "square.stack", theme: t)
                        StatRow(label: "Theme", value: t.name, icon: "paintpalette", theme: t)
                    }
                }

                // Exports section
                CollapsibleSection(title: "EXPORTS", icon: "square.and.arrow.up", theme: t) {
                    VStack(spacing: 6) {
                        let docs = folderManager.listDocuments()
                        if docs.isEmpty {
                            HStack {
                                Image(systemName: "tray")
                                    .foregroundColor(t.mutedColor.opacity(0.5))
                                Text("No exports yet")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.mutedColor)
                            }
                            .padding(10)
                        } else {
                            ForEach(docs, id: \.path) { url in
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.zipper")
                                        .font(.system(size: 11))
                                        .foregroundColor(t.mutedColor)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.03))
                                )
                            }
                        }
                    }
                }

                // Dynamic Island section
                CollapsibleSection(title: "DYNAMIC ISLAND", icon: "island", theme: t) {
                    DynamicIslandControlView()
                }

                // Edition section
                CollapsibleSection(title: "EDITION", icon: "crown", theme: t) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.edition.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(t.accent)
                            Text(vm.edition.price)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }
                        Spacer()
                        Image(systemName: vm.edition == .enterprise ? "crown.fill" : "crown")
                            .font(.system(size: 18))
                            .foregroundColor(t.accent.opacity(0.5))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(t.accent.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.surfaceBorder.opacity(0.5), lineWidth: 0.5))
                    )
                }
            }
            .padding(16)
        }
        .background(
            t.surface.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(width: 0.5), alignment: .leading)
    }
}

// MARK: - Collapsible Section

struct CollapsibleSection<Content: View>: View {
    @EnvironmentObject var vm: EditorViewModel
    let title: String
    let icon: String
    let theme: ParadiseTheme
    @ViewBuilder let content: () -> Content
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(theme.accent.opacity(0.7))
                    Text(title)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                        .tracking(1.2)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.mutedColor.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
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
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.mutedColor.opacity(0.4))
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder.opacity(0.5), lineWidth: 0.5))
            )
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
    var icon: String = ""
    let theme: ParadiseTheme
    var body: some View {
        HStack(spacing: 8) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(theme.mutedColor.opacity(0.5))
                    .frame(width: 18)
            }
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(theme.mutedColor)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(theme.accent)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
    }
}
