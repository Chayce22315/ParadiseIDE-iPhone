import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @State private var sidebarVisible = false
    @State private var terminalVisible = false
    @State private var terminalHeight: CGFloat = 320
    @State private var rightPanelVisible = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            let isLargeScreen = geo.size.width > 700

            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.2), value: vm.theme.id)

                if !vm.performanceMode { ParticleLayerView().ignoresSafeArea() }

                VStack(spacing: 0) {
                    DynamicIslandView()
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 6)

                    TopBarView(
                        sidebarVisible: $sidebarVisible,
                        terminalVisible: $terminalVisible,
                        rightPanelVisible: $rightPanelVisible
                    )

                    if isLargeScreen {
                        HStack(spacing: 0) {
                            if sidebarVisible {
                                FileTreeView()
                                    .frame(width: min(260, geo.size.width * 0.28))
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            }
                            EditorView()
                            if rightPanelVisible {
                                RightPanelView()
                                    .frame(width: min(220, geo.size.width * 0.26))
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    } else {
                        EditorView()
                    }

                    if terminalVisible {
                        VStack(spacing: 0) {
                            TerminalPanelHeader(terminalHeight: $terminalHeight, terminalVisible: $terminalVisible, theme: t)
                            TerminalView()
                                .frame(height: min(terminalHeight, geo.size.height * 0.45))
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    StatusBarView()
                }

                if !isLargeScreen && sidebarVisible {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.3)) { sidebarVisible = false } }
                        .transition(.opacity)

                    HStack(spacing: 0) {
                        FileTreeView()
                            .frame(width: min(300, geo.size.width * 0.75))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: t.accent.opacity(0.2), radius: 30)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.leading, 8)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Spacer()
                    }
                }

                if !isLargeScreen && rightPanelVisible {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.3)) { rightPanelVisible = false } }
                        .transition(.opacity)

                    VStack {
                        Spacer()
                        RightPanelView()
                            .frame(maxHeight: geo.size.height * 0.6)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: t.accent.opacity(0.15), radius: 30)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if vm.showErrorToast {
                    ErrorToastView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sidebarVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: terminalVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: rightPanelVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showErrorToast)
            .sheet(isPresented: $vm.showExportPanel) {
                ExportView().environmentObject(vm)
            }
            .sheet(isPresented: $vm.showSettingsPanel) {
                SettingsView().environmentObject(vm)
            }
            .sheet(isPresented: $vm.showSnippetsPanel) {
                SnippetsView().environmentObject(vm)
            }
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
            Image(systemName: "terminal").font(.system(size: 12)).foregroundColor(theme.mutedColor)
            Text("TERMINAL").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(theme.mutedColor)
            Spacer()
            ForEach([("S", 200.0), ("M", 320.0), ("L", 460.0)], id: \.0) { label, h in
                Button(label) {
                    withAnimation(.spring(response: 0.3)) { terminalHeight = h }
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(abs(terminalHeight - h) < 1 ? theme.accent : theme.mutedColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(
                    Capsule().fill(abs(terminalHeight - h) < 1 ? theme.accent.opacity(0.15) : Color.clear)
                )
                .buttonStyle(.plain)
            }
            Button { withAnimation { terminalVisible = false } } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain).padding(.trailing, 12)
        }
        .frame(height: 34)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(theme.surfaceBorder), alignment: .top)
        .gesture(DragGesture().onChanged { value in
            let newHeight = terminalHeight - value.translation.height
            terminalHeight = max(160, min(600, newHeight))
        })
    }
}
