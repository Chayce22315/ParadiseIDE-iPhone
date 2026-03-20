import SwiftUI

@main
struct ParadiseIDEApp: App {
    @StateObject private var editorVM = EditorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editorVM)
                .preferredColorScheme(.dark)
        }
    }
}
