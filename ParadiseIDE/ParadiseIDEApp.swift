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
                    startIsland()
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .background:
                        updateIsland(status: "Background")
                    case .active:
                        updateIsland(status: "Coding")
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
        manager.startLiveActivity(
            fileName: editorVM.activeTab?.name ?? "Paradise IDE",
            lineCount: editorVM.lineCount,
            language: editorVM.activeTab?.language ?? "swift",
            tabCount: editorVM.tabs.count
        )
    }

    private func updateIsland(status: String) {
        let manager = DynamicIslandManager.shared
        manager.updateLiveActivity(
            fileName: editorVM.activeTab?.name ?? "Paradise IDE",
            lineCount: editorVM.lineCount,
            language: editorVM.activeTab?.language ?? "swift",
            status: status,
            tabCount: editorVM.tabs.count,
            aiActive: editorVM.showAIPanel
        )
    }
}
