import SwiftUI

struct RightPanelView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                PanelSection(title: "AI CO-PILOT") {
                    VStack(spacing: 6) {
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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "doc")
                                    .foregroundColor(t.accent).font(.system(size: 11))
                                Text(tab.name)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.accent).lineLimit(1)
                                if tab.isDirty {
                                    Text("(unsaved)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            Text(tab.language.uppercased())
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(t.accent.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
                    } else {
                        Text("No file open")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                }

                PanelSection(title: "STATS") {
                    VStack(alignment: .leading, spacing: 4) {
                        StatRow(label: "Lines",  value: "\(vm.lineCount)", theme: t)
                        StatRow(label: "Chars",  value: "\(vm.code.count)", theme: t)
                        StatRow(label: "Tabs",   value: "\(vm.tabs.count)", theme: t)
                        StatRow(label: "Theme",  value: t.name, theme: t)
                    }
                }

                PanelSection(title: "EXPORTS") {
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
                                .background(Color.black.opacity(0.15))
                                .cornerRadius(5)
                            }
                        }
                    }
                }

                PanelSection(title: "EDITION") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.edition.rawValue)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(t.accent)
                        Text(vm.edition.price)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(t.accent.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
                }
            }
            .padding(12)
        }
        .background(t.surface)
        .overlay(Rectangle().frame(width: 1).foregroundColor(t.surfaceBorder), alignment: .leading)
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
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(theme.accent)
                Text(label).font(.system(size: 11, design: .monospaced)).foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(theme.mutedColor)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.black.opacity(0.2))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.surfaceBorder, lineWidth: 1))
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
            Text(label + ":").font(.system(size: 10, design: .monospaced)).foregroundColor(theme.mutedColor)
            Spacer()
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.accent)
        }
    }
}
