import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: EditorViewModel
    @State private var sidebarVisible = true
    @State private var terminalVisible = false
    @State private var terminalHeight: CGFloat = 280

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: t.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.2), value: vm.theme.id)

            if !vm.performanceMode {
                ParticleLayerView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                TopBarView(sidebarVisible: $sidebarVisible, terminalVisible: $terminalVisible)

                HStack(spacing: 0) {
                    if sidebarVisible {
                        FileTreeView()
                            .frame(width: 170)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    EditorView()

                    RightPanelView()
                        .frame(width: 190)
                }

                if terminalVisible {
                    VStack(spacing: 0) {
                        TerminalPanelHeader(
                            terminalHeight: $terminalHeight,
                            terminalVisible: $terminalVisible,
                            theme: t
                        )
                        TerminalView()
                            .frame(height: terminalHeight)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: sidebarVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: terminalVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.showErrorToast)
        .sheet(isPresented: $vm.showExportPanel) {
            ExportView()
                .environmentObject(vm)
        }
    }
}

// MARK: - Terminal panel header with drag resize

struct TerminalPanelHeader: View {
    @Binding var terminalHeight: CGFloat
    @Binding var terminalVisible: Bool
    let theme: ParadiseTheme

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.mutedColor.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.leading, 12)

            Text("🖥️ TERMINAL")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(theme.mutedColor)
                .tracking(1.5)

            Spacer()

            ForEach([("S", 180.0), ("M", 280.0), ("L", 420.0)], id: \.0) { label, h in
                Button(label) {
                    withAnimation(.spring(response: 0.3)) { terminalHeight = h }
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(abs(terminalHeight - h) < 1 ? theme.accent : theme.mutedColor)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(abs(terminalHeight - h) < 1 ? theme.accent.opacity(0.15) : Color.clear)
                )
                .buttonStyle(.plain)
            }

            Button {
                withAnimation { terminalVisible = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.mutedColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
        .frame(height: 30)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().frame(height: 1).foregroundColor(theme.surfaceBorder), alignment: .top)
        .gesture(
            DragGesture().onChanged { value in
                let newHeight = terminalHeight - value.translation.height
                terminalHeight = max(140, min(560, newHeight))
            }
        )
    }
}
