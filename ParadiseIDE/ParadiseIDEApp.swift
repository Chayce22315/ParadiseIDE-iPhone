import SwiftUI

@main
struct ParadiseIDEApp: App {
    @StateObject private var editorVM = EditorViewModel()
    @StateObject private var folderManager = FolderManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editorVM)
                .environmentObject(folderManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    editorVM.startLiveActivity()
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active:
                        if !editorVM.isLiveActivityRunning {
                            editorVM.startLiveActivity()
                        }
                        DynamicIslandPresenter.shared.updateSession(vm: editorVM)
                    case .background:
                        DynamicIslandPresenter.shared.updateSession(vm: editorVM)
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}
