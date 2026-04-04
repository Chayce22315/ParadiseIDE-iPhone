import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @State private var sidebarVisible = true
    @State private var terminalVisible = false
    @State private var terminalHeight: CGFloat = 280
    @State private var showCommandPalette = false
    @State private var showDynamicIsland = true
    @StateObject private var liveActivity = LiveActivityManager.shared

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            let isLargeDevice = geo.size.height > 800
            let sidebarWidth: CGFloat = isLargeDevice ? 220 : 200
            let rightPanelWidth: CGFloat = isLargeDevice ? 200 : 180

            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.2), value: vm.theme.id)

                if !vm.performanceMode { ParticleLayerView().ignoresSafeArea() }

                VStack(spacing: 0) {
                    if showDynamicIsland {
                        DynamicIslandBanner()
                            .padding(.top, 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    TopBarView(
                        sidebarVisible: $sidebarVisible,
                        terminalVisible: $terminalVisible,
                        showCommandPalette: $showCommandPalette,
                        showDynamicIsland: $showDynamicIsland
                    )

                    HStack(spacing: 0) {
                        if sidebarVisible {
                            FileTreeView()
                                .frame(width: sidebarWidth)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        EditorView()

                        RightPanelView()
                            .frame(width: rightPanelWidth)
                    }

                    if terminalVisible {
                        VStack(spacing: 0) {
                            TerminalPanelHeader(terminalHeight: $terminalHeight, terminalVisible: $terminalVisible, theme: t, isLargeDevice: isLargeDevice)
                            TerminalView()
                                .frame(height: min(terminalHeight, geo.size.height * 0.45))
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

                if showCommandPalette {
                    CommandPaletteView(
                        isPresented: $showCommandPalette,
                        sidebarVisible: $sidebarVisible,
                        terminalVisible: $terminalVisible
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(20)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sidebarVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: terminalVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showErrorToast)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showCommandPalette)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showDynamicIsland)
            .sheet(isPresented: $vm.showExportPanel) {
                ExportView().environmentObject(vm)
            }
            .onAppear {
                liveActivity.startSession(
                    projectName: folderManager.rootName,
                    fileName: vm.selectedFile,
                    language: vm.activeTab?.language ?? "swift",
                    lineCount: vm.lineCount,
                    charCount: vm.code.count,
                    themeName: t.name,
                    petEmoji: t.petEmoji
                )
            }
            .onChange(of: vm.code) { _ in
                liveActivity.updateActivity(
                    fileName: vm.selectedFile,
                    language: vm.activeTab?.language ?? "swift",
                    lineCount: vm.lineCount,
                    charCount: vm.code.count,
                    themeName: t.name,
                    petEmoji: t.petEmoji,
                    isDirty: vm.activeTab?.isDirty ?? false
                )
            }
        }
    }
}

struct TerminalPanelHeader: View {
    @Binding var terminalHeight: CGFloat
    @Binding var terminalVisible: Bool
    let theme: ParadiseTheme
    let isLargeDevice: Bool

    private var sizeOptions: [(String, CGFloat)] {
        if isLargeDevice {
            return [("S", 200), ("M", 320), ("L", 480)]
        } else {
            return [("S", 160), ("M", 260), ("L", 380)]
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.mutedColor.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.leading, 12)

            Image(systemName: "terminal")
                .font(.system(size: 11))
                .foregroundColor(theme.mutedColor)

            Text("TERMINAL")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.mutedColor)

            Spacer()

            ForEach(sizeOptions, id: \.0) { label, h in
                Button(label) {
                    withAnimation(.spring(response: 0.3)) { terminalHeight = h }
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(abs(terminalHeight - h) < 1 ? theme.accent : theme.mutedColor)
                .buttonStyle(.plain)
            }

            Button { withAnimation { terminalVisible = false } } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(theme.mutedColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
        .frame(height: 30)
        .background(.ultraThinMaterial)
        .overlay(FrostedDivider(theme.surfaceBorder), alignment: .top)
        .gesture(DragGesture().onChanged { value in
            let newHeight = terminalHeight - value.translation.height
            let maxH: CGFloat = isLargeDevice ? 600 : 480
            terminalHeight = max(140, min(maxH, newHeight))
        })
    }
}
