import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @EnvironmentObject var github: GitHubService
    @State private var sidebarVisible = true
    @State private var terminalVisible = false
    @State private var terminalHeight: CGFloat = 320

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            let isLargePhone = geo.size.height > 800

            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.2), value: vm.theme.id)

                if !vm.performanceMode { ParticleLayerView().ignoresSafeArea() }

                VStack(spacing: 0) {
                    DynamicIslandBannerView()
                        .padding(.top, isLargePhone ? 4 : 2)

                    TopBarView(sidebarVisible: $sidebarVisible, terminalVisible: $terminalVisible)

                    HStack(spacing: 0) {
                        if sidebarVisible {
                            FileTreeView()
                                .frame(width: isLargePhone ? 220 : 180)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        EditorView()

                        if isLargePhone {
                            RightPanelView()
                                .frame(width: 200)
                        }
                    }

                    if terminalVisible {
                        VStack(spacing: 0) {
                            TerminalPanelHeader(terminalHeight: $terminalHeight, terminalVisible: $terminalVisible, theme: t)
                            TerminalView()
                                .frame(height: min(terminalHeight, geo.size.height * 0.4))
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    StatusBarView()
                }

                if vm.showErrorToast {
                    ErrorToastView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sidebarVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: terminalVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showErrorToast)
        .fullScreenCover(isPresented: $folderManager.showPicker) {
            FolderPicker(
                onPick: { url in
                    folderManager.showPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        folderManager.openFolder(url)
                    }
                },
                onCancel: { folderManager.showPicker = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $vm.showExportPanel) {
            ExportView().environmentObject(vm)
        }
        .sheet(isPresented: $vm.showSettingsPanel) {
            AppSettingsView()
                .environmentObject(vm)
                .environmentObject(github)
        }
        .sheet(isPresented: $vm.showSnippetsPanel) {
            SnippetsLibraryView().environmentObject(vm)
        }
    }
}

struct TerminalPanelHeader: View {
    @Binding var terminalHeight: CGFloat
    @Binding var terminalVisible: Bool
    let theme: ParadiseTheme

    var body: some View {
        HStack(spacing: 10) {
            Capsule().fill(theme.mutedColor.opacity(0.4)).frame(width: 36, height: 4).padding(.leading, 12)
            Image(systemName: "terminal").font(.system(size: 11)).foregroundColor(theme.mutedColor)
            Text("TERMINAL").font(.system(size: 10, design: .monospaced)).foregroundColor(theme.mutedColor)
            Spacer()
            ForEach([("S", 200.0), ("M", 320.0), ("L", 480.0)], id: \.0) { label, h in
                Button(label) {
                    withAnimation(.spring(response: 0.3)) { terminalHeight = h }
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(abs(terminalHeight - h) < 1 ? theme.accent : theme.mutedColor)
                .buttonStyle(.plain)
            }
            Button { withAnimation { terminalVisible = false } } label: {
                Image(systemName: "xmark").font(.system(size: 11)).foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain).padding(.trailing, 12)
        }
        .frame(height: 32)
        .liquidGlassToolbar(theme: theme)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(theme.surfaceBorder), alignment: .top)
        .gesture(DragGesture().onChanged { value in
            let newHeight = terminalHeight - value.translation.height
            terminalHeight = max(160, min(600, newHeight))
        })
    }
}
