import SwiftUI

@main
struct ParadiseIDEApp: App {
    @StateObject private var editorVM = EditorViewModel()
    @StateObject private var folderManager = FolderManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editorVM)
                .environmentObject(folderManager)
                .preferredColorScheme(.dark)
        }
    }
}
