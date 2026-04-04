import SwiftUI

@main
struct ParadiseIDEApp: App {
    @StateObject private var editorVM = EditorViewModel()
    @StateObject private var folderManager = FolderManager()
    @StateObject private var githubService = GitHubService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editorVM)
                .environmentObject(folderManager)
                .environmentObject(githubService)
                .preferredColorScheme(.dark)
                .onAppear {
                    AppIconExporter.generateIfNeeded()
                }
        }
    }
}
