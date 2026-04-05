import SwiftUI

@main
struct ParadiseIDEApp: App {
    @StateObject private var editorVM = EditorViewModel()
    @StateObject private var folderManager = FolderManager()
    @StateObject private var githubService = GitHubService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editorVM)
                .environmentObject(folderManager)
                .environmentObject(githubService)
                .preferredColorScheme(.dark)
                .onAppear {
                    AppIconExporter.generateIfNeeded()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startIsland()
                    }
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .background:
                        updateIsland(status: "Background")
                    case .active:
                        startIsland()
                    case .inactive:
                        updateIsland(status: "Paused")
                    @unknown default:
                        break
                    }
                }
                .onChange(of: editorVM.activeTabID) { _ in
                    updateIsland(status: "Coding")
                }
                .onChange(of: editorVM.lineCount) { _ in
                    updateIsland(status: "Coding")
                }
        }
    }

    private func startIsland() {
        let manager = DynamicIslandManager.shared
        let fileName = editorVM.activeTab?.name ?? "Paradise IDE"
        let lang = editorVM.activeTab?.language ?? "swift"
        let lines = max(editorVM.lineCount, 1)
        let tabs = max(editorVM.tabs.count, 0)

        if manager.isLiveActivityRunning {
            manager.updateLiveActivity(
                fileName: fileName,
                lineCount: lines,
                language: lang,
                status: "Coding",
                tabCount: tabs,
                aiActive: editorVM.showAIPanel
            )
        } else {
            manager.startLiveActivity(
                fileName: fileName,
                lineCount: lines,
                language: lang,
                tabCount: tabs
            )
        }
    }

    private func updateIsland(status: String) {
        let manager = DynamicIslandManager.shared
        guard manager.isLiveActivityRunning else { return }
        manager.updateLiveActivity(
            fileName: editorVM.activeTab?.name ?? "Paradise IDE",
            lineCount: max(editorVM.lineCount, 1),
            language: editorVM.activeTab?.language ?? "swift",
            status: status,
            tabCount: max(editorVM.tabs.count, 0),
            aiActive: editorVM.showAIPanel
        )
    }
}
