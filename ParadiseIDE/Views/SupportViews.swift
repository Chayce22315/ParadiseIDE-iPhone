import SwiftUI

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                if let tab = vm.activeTab {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 9))
                        Text(tab.name)
                            .lineLimit(1)
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.mutedColor)

                    Text(tab.language.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent.opacity(0.7))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(t.accent.opacity(0.08)))
                }

                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 9))
                    Text("Ln \(vm.lineCount)")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(t.mutedColor)

                Text(t.petEmoji)
                    .font(.system(size: 12))
            }

            Spacer()

            HStack(spacing: 8) {
                if vm.isLiveActivityRunning {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 5, height: 5)
                        Text("Live")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }

                Text("Paradise IDE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(
            t.accent.opacity(0.06)
                .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(height: 0.5), alignment: .top)
    }
}

// MARK: - Error Toast

struct ErrorToastView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(t.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PARADISE TOOLS")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Text("No stress! The AI can help fix this issue.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(t.textColor)
                        .lineSpacing(2)
                }

                Spacer()

                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(t.mutedColor)
                        .font(.system(size: 16))
                }.buttonStyle(.plain)
            }
            .glassCard(theme: t, cornerRadius: 18, padding: 16)
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
    }
}

// MARK: - Particle Layer

struct ParticleLayerView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(t.particles.enumerated()), id: \.offset) { i, emoji in
                Text(emoji)
                    .font(.system(size: CGFloat(20 + (i % 3) * 10)))
                    .position(
                        x: geo.size.width * (0.10 + Double(i) * 0.18 + Double(i % 2) * 0.08),
                        y: geo.size.height * (0.05 + Double(i % 4) * 0.22)
                    )
                    .opacity(0.08 + Double(i % 3) * 0.03)
                    .blur(radius: 0.8)
                    .modifier(FloatModifier(delay: Double(i) * 0.7, range: 20))
            }
        }
    }
}

struct FloatModifier: ViewModifier {
    let delay: Double
    let range: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content.offset(y: offset).onAppear {
            withAnimation(.easeInOut(duration: 3.5 + delay * 0.4).repeatForever(autoreverses: true).delay(delay)) {
                offset = -range
            }
        }
    }
}

// MARK: - Snippets View

struct SnippetsView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    var t: ParadiseTheme { vm.theme }

    let snippets: [(name: String, icon: String, code: String)] = [
        ("SwiftUI View", "rectangle.on.rectangle",
         "struct MyView: View {\n    var body: some View {\n        VStack {\n            Text(\"Hello, World!\")\n        }\n    }\n}"),
        ("Async Function", "arrow.triangle.2.circlepath",
         "func fetchData() async throws -> Data {\n    let url = URL(string: \"https://api.example.com\")!\n    let (data, _) = try await URLSession.shared.data(from: url)\n    return data\n}"),
        ("Observable Class", "eye",
         "@Observable\nclass ViewModel {\n    var items: [String] = []\n    var isLoading = false\n    \n    func load() async {\n        isLoading = true\n        // fetch items\n        isLoading = false\n    }\n}"),
        ("Enum with Cases", "list.bullet",
         "enum AppState: String, CaseIterable {\n    case idle\n    case loading\n    case loaded\n    case error\n}"),
        ("ForEach List", "list.dash",
         "List {\n    ForEach(items) { item in\n        HStack {\n            Text(item.name)\n            Spacer()\n            Text(item.detail)\n                .foregroundStyle(.secondary)\n        }\n    }\n}"),
        ("API Request", "network",
         "func apiRequest(endpoint: String) async throws -> [String: Any] {\n    var request = URLRequest(url: URL(string: endpoint)!)\n    request.httpMethod = \"GET\"\n    request.setValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")\n    let (data, _) = try await URLSession.shared.data(for: request)\n    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]\n}"),
        ("Error Handling", "exclamationmark.triangle",
         "do {\n    let result = try await riskyOperation()\n    print(\"Success: \\(result)\")\n} catch let error as URLError {\n    print(\"Network error: \\(error.localizedDescription)\")\n} catch {\n    print(\"Unexpected error: \\(error)\")\n}"),
        ("UserDefaults", "gearshape.2",
         "@AppStorage(\"username\") var username: String = \"\"\n@AppStorage(\"isOnboarded\") var isOnboarded: Bool = false"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(snippets, id: \.name) { snippet in
                            Button {
                                vm.code += "\n\n" + snippet.code
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: snippet.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(t.accent)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(t.accent.opacity(0.12))
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(snippet.name)
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(t.textColor)
                                        Text(snippet.code.prefix(60) + "...")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(t.mutedColor)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(t.accent.opacity(0.5))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(t.surface.opacity(0.5))
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.surfaceBorder.opacity(0.5), lineWidth: 0.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Code Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @StateObject private var aiService = AIService()
    @Environment(\.dismiss) private var dismiss
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        QuickActionSection(title: "FILE", theme: t) {
                            QuickActionRow(icon: "doc.badge.plus", label: "New File", theme: t) {
                                vm.newUntitledTab()
                                dismiss()
                            }
                            QuickActionRow(icon: "folder.badge.plus", label: "Open Folder", theme: t) {
                                folderManager.showPicker = true
                                dismiss()
                            }
                            QuickActionRow(icon: "square.and.arrow.down", label: "Save", theme: t) {
                                vm.saveActiveTab(using: folderManager)
                                dismiss()
                            }
                            QuickActionRow(icon: "square.and.arrow.up", label: "Export", theme: t) {
                                vm.showExportPanel = true
                                dismiss()
                            }
                        }

                        QuickActionSection(title: "EDIT", theme: t) {
                            QuickActionRow(icon: "magnifyingglass", label: "Find & Replace", theme: t) {
                                vm.showFindReplace = true
                                dismiss()
                            }
                            QuickActionRow(icon: "arrow.uturn.backward", label: "Clear Code", theme: t) {
                                vm.code = ""
                                dismiss()
                            }
                            QuickActionRow(icon: "doc.on.doc", label: "Duplicate Tab", theme: t) {
                                if let tab = vm.activeTab {
                                    vm.newUntitledTab(language: tab.language)
                                    vm.code = tab.content
                                }
                                dismiss()
                            }
                        }

                        QuickActionSection(title: "AI", theme: t) {
                            QuickActionRow(icon: "sparkles", label: "AI Review", theme: t) {
                                Task {
                                    let r = await aiService.complete(prompt: "Review this code.", context: vm.code)
                                    vm.aiResponse = r; vm.showAIPanel = true
                                }
                                dismiss()
                            }
                            QuickActionRow(icon: "wrench.and.screwdriver", label: "AI Fix", theme: t) {
                                Task {
                                    let r = await aiService.fixCode(vm.code)
                                    vm.aiResponse = r; vm.showAIPanel = true
                                }
                                dismiss()
                            }
                            QuickActionRow(icon: "text.magnifyingglass", label: "AI Explain", theme: t) {
                                Task {
                                    let r = await aiService.explainCode(vm.code)
                                    vm.aiResponse = r; vm.showAIPanel = true
                                }
                                dismiss()
                            }
                        }

                        QuickActionSection(title: "VIEW", theme: t) {
                            QuickActionRow(icon: "lightbulb", label: "Guide Mode", theme: t) {
                                vm.guideMode.toggle()
                                dismiss()
                            }
                            QuickActionRow(icon: "hare", label: "Performance Mode", theme: t) {
                                vm.performanceMode.toggle()
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

struct QuickActionSection: View {
    let title: String
    let theme: ParadiseTheme
    @ViewBuilder let content: () -> some View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(theme.mutedColor)
                .tracking(1.5)
                .padding(.leading, 4)
            content()
        }
    }
}

struct QuickActionRow: View {
    let icon: String
    let label: String
    let theme: ParadiseTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(theme.textColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.mutedColor.opacity(0.3))
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface.opacity(0.4))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.surfaceBorder.opacity(0.4), lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }
}
