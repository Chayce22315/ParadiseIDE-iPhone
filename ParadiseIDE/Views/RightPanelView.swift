import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                PanelSection(title: "AI CO-PILOT") {
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
                        AIActionButton(label: "Review Code", icon: "checkmark.seal", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Review this code for bugs, style, and improvements.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                        AIActionButton(label: "Add Comments", icon: "text.bubble", theme: t) {
                            Task {
                                let r = await aiService.complete(prompt: "Add inline documentation comments to this code. Return the full commented code.", context: vm.code)
                                vm.aiResponse = r; vm.showAIPanel = true
                            }
                        }
                    }
                }

                PanelSection(title: "CURRENT FILE") {
                    if let tab = vm.activeTab {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(t.accent.opacity(0.12)).frame(width: 34, height: 34)
                                Image(systemName: "doc.fill")
                                    .foregroundColor(t.accent).font(.system(size: 14))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tab.name)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(t.accent).lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(tab.language.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(t.accent.opacity(0.7))
                                    if tab.isDirty {
                                        Text("unsaved")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(theme: t, cornerRadius: 12)
                    } else {
                        Text("No file open")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                }

                PanelSection(title: "STATS") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        StatCard(icon: "text.alignleft", label: "Lines", value: "\(vm.lineCount)", theme: t)
                        StatCard(icon: "character.cursor.ibeam", label: "Chars", value: "\(vm.code.count)", theme: t)
                        StatCard(icon: "doc.on.doc", label: "Tabs", value: "\(vm.tabs.count)", theme: t)
                        StatCard(icon: "paintpalette", label: "Theme", value: t.name, theme: t)
                    }
                }

                PanelSection(title: "QUICK ACTIONS") {
                    VStack(spacing: 8) {
                        QuickActionButton(label: "Format Code", icon: "text.alignleft", theme: t) {
                            vm.formatCode()
                        }
                        QuickActionButton(label: "Duplicate Line", icon: "doc.on.doc", theme: t) {
                            vm.duplicateCurrentLine()
                        }
                        QuickActionButton(label: "Toggle Comment", icon: "text.bubble", theme: t) {
                            vm.toggleComment()
                        }
                    }
                }

                PanelSection(title: "EXPORTS") {
                    VStack(spacing: 6) {
                        let docs = folderManager.listDocuments()
                        if docs.isEmpty {
                            HStack {
                                Image(systemName: "tray").foregroundColor(t.mutedColor.opacity(0.4))
                                Text("No exports yet")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.mutedColor)
                            }
                        } else {
                            ForEach(docs, id: \.path) { url in
                                HStack {
                                    Image(systemName: "doc.zipper").font(.system(size: 10)).foregroundColor(t.mutedColor)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(t.textColor).lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.1)))
                            }
                        }
                    }
                }

                PanelSection(title: "EDITION") {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vm.edition.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(t.accent)
                            Text(vm.edition.price)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(t.accent.opacity(0.3))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(theme: t, cornerRadius: 12)
                }
            }
            .padding(14)
        }
        .background(.ultraThinMaterial.opacity(0.4))
        .overlay(Rectangle().frame(width: 0.5).foregroundColor(t.surfaceBorder), alignment: .leading)
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
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(theme.accent)
                Text(label).font(.system(size: 12, design: .monospaced)).foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .medium)).foregroundColor(theme.mutedColor.opacity(0.5))
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder, lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionButton: View {
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
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.surfaceBorder, lineWidth: 0.5))
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(vm.theme.mutedColor)
                .tracking(1.5)
            content()
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let theme: ParadiseTheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(theme.accent)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(theme.mutedColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder, lineWidth: 0.5))
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let theme: ParadiseTheme
    var body: some View {
        HStack {
            Text(label + ":").font(.system(size: 10, design: .monospaced)).foregroundColor(theme.mutedColor)
            Spacer()
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.accent)
        }
    }
}
