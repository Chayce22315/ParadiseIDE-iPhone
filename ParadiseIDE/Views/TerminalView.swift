import SwiftUI

// MARK: - TerminalView

struct TerminalView: View {
    @EnvironmentObject var editorVM: EditorViewModel
    @StateObject private var bridge = TerminalBridge()
    @StateObject private var history = InputHistory()
    @StateObject private var autocomplete = AutocompleteEngine()
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false

    var t: ParadiseTheme { editorVM.theme }

    var body: some View {
        VStack(spacing: 0) {
            TerminalTopBar(
                bridge: bridge,
                theme: t,
                showSettings: $showSettings,
                onSendFile: {
                    let name = editorVM.selectedFile
                    let content = editorVM.code
                    Task { await bridge.writeFile(name: name, content: content) }
                }
            )

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    OutputScrollView(bridge: bridge, theme: t)

                    if autocomplete.isVisible {
                        AutocompleteDropdown(engine: autocomplete, theme: t) { chosen in
                            input = chosen
                            autocomplete.hide()
                            inputFocused = true
                        }
                    }

                    InputBar(
                        input: $input,
                        isFocused: $inputFocused,
                        bridge: bridge,
                        history: history,
                        autocomplete: autocomplete,
                        theme: t
                    ) { cmd in submit(cmd) }
                }

                WorkspacePanel(bridge: bridge, theme: t) { file in
                    bridge.send(command: "cat \(file.path)")
                    Task { await loadFileIntoEditor(file: file) }
                }
                .frame(width: 180)
            }
        }
        .background(Color.black.opacity(0.35).background(.ultraThinMaterial))
        .onAppear {
            bridge.host = "localhost"
            bridge.port = "8765"
            bridge.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                inputFocused = true
            }
        }
        .onDisappear { bridge.disconnect() }
        .sheet(isPresented: $showSettings) {
            TerminalSettingsSheet(bridge: bridge, theme: t)
        }
    }

    private func submit(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        history.push(trimmed)
        autocomplete.hide()
        bridge.buffer.appendInput("> \(trimmed)")
        bridge.buffer.isRunning = true
        bridge.send(command: trimmed)
        input = ""
    }

    private func loadFileIntoEditor(file: WorkspaceFile) async {
        guard let url = bridge.downloadURL(for: file.path) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let content = String(data: data, encoding: .utf8) {
                await MainActor.run {
                    editorVM.onCodeChange(content)
                    editorVM.selectedFile = file.name
                }
            }
        } catch { }
    }
}

// MARK: - Top bar

struct TerminalTopBar: View {
    @ObservedObject var bridge: TerminalBridge
    let theme: ParadiseTheme
    @Binding var showSettings: Bool
    let onSendFile: () -> Void

    var dotColor: Color {
        switch bridge.state {
        case .connected:    return .green
        case .connecting:   return .yellow
        case .error:        return .red
        case .disconnected: return theme.mutedColor
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("TERMINAL")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(theme.mutedColor)

            HStack(spacing: 5) {
                Circle().fill(dotColor).frame(width: 7, height: 7)
                    .shadow(color: dotColor.opacity(0.8), radius: 4)
                Text(bridge.state.label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(dotColor)
            }

            Text("ws://\(bridge.host):\(bridge.port)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(theme.mutedColor.opacity(0.5))

            Spacer()

            Button("Send File", action: onSendFile)
                .termBarButton(color: theme.accent2)

            if bridge.state.isConnected {
                Button("Disconnect") { bridge.disconnect() }
                    .termBarButton(color: .red.opacity(0.9))
            } else {
                Button("Connect") { bridge.connect() }
                    .termBarButton(color: theme.accent)
            }

            Button {
                bridge.buffer.clear()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundColor(theme.mutedColor)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(Color.black.opacity(0.4).background(.ultraThinMaterial))
        .overlay(
            Rectangle()
                .fill(theme.surfaceBorder.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Output scroll view

struct OutputScrollView: View {
    @ObservedObject var bridge: TerminalBridge
    let theme: ParadiseTheme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(bridge.buffer.lines) { line in
                        ANSITextView(line.raw, defaultColor: line.defaultColor)
                            .id(line.id)
                            .padding(.horizontal, 14)
                    }
                    if bridge.buffer.isRunning {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.5).tint(theme.accent)
                            Text("running...")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(theme.mutedColor)
                        }
                        .padding(.horizontal, 14)
                        .id("spinner")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: bridge.buffer.lines.count) { _ in
                if let last = bridge.buffer.lines.last {
                    withAnimation(.none) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .background(Color.black.opacity(0.25))
    }
}

// MARK: - Autocomplete dropdown

struct AutocompleteDropdown: View {
    @ObservedObject var engine: AutocompleteEngine
    let theme: ParadiseTheme
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(engine.suggestions, id: \.self) { suggestion in
                Button { onSelect(suggestion) } label: {
                    Text(suggestion)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(theme.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.03))
                if suggestion != engine.suggestions.last {
                    Divider().background(theme.surfaceBorder.opacity(0.3))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.75))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder.opacity(0.5), lineWidth: 0.5))
        )
        .padding(.horizontal, 14).padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeOut(duration: 0.15), value: engine.suggestions)
    }
}

// MARK: - Input bar

struct InputBar: View {
    @Binding var input: String
    var isFocused: FocusState<Bool>.Binding
    let bridge: TerminalBridge
    let history: InputHistory
    let autocomplete: AutocompleteEngine
    let theme: ParadiseTheme
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(">")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(theme.accent)

            TextField("Enter command...", text: $input)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(theme.textColor)
                .tint(theme.accent)
                .focused(isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: input) { autocomplete.update(input: $0) }
                .onSubmit { onSubmit(input) }

            HStack(spacing: 6) {
                Button {
                    input = history.up(current: input)
                    autocomplete.update(input: input)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                }.buttonStyle(.plain)

                Button {
                    input = history.down()
                    autocomplete.update(input: input)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                }.buttonStyle(.plain)
            }

            Button { onSubmit(input) } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(input.isEmpty ? theme.mutedColor.opacity(0.3) : theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(input.isEmpty || !bridge.state.isConnected)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.black.opacity(0.45).background(.ultraThinMaterial))
        .overlay(Rectangle().fill(theme.surfaceBorder.opacity(0.3)).frame(height: 0.5), alignment: .top)
        .onTapGesture { isFocused.wrappedValue = true }
    }
}

// MARK: - Workspace panel

struct WorkspacePanel: View {
    @ObservedObject var bridge: TerminalBridge
    let theme: ParadiseTheme
    let onFileTap: (WorkspaceFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("WORKSPACE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.mutedColor)
                Spacer()
                Button { bridge.send(command: "files") } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(theme.mutedColor)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)

            Divider().background(theme.surfaceBorder.opacity(0.3))

            if bridge.workspaceFiles.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 22))
                        .foregroundColor(theme.mutedColor.opacity(0.3))
                    Text("No files yet")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                    Text("download <url>\nor run a script")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.mutedColor.opacity(0.5))
                        .multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(bridge.workspaceFiles) { file in
                            WorkspaceFileRow(file: file, theme: theme) { onFileTap(file) }
                        }
                    }.padding(10)
                }
            }

            Divider().background(theme.surfaceBorder.opacity(0.3))
            Text("Session: \(String(bridge.sessionID.prefix(8)))...")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(theme.mutedColor.opacity(0.3))
                .padding(10)
        }
        .background(Color.black.opacity(0.2).background(.ultraThinMaterial))
        .overlay(Rectangle().fill(theme.surfaceBorder.opacity(0.3)).frame(width: 0.5), alignment: .leading)
    }
}

struct WorkspaceFileRow: View {
    let file: WorkspaceFile
    let theme: ParadiseTheme
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(file.icon)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.mutedColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                    Text(file.sizeLabel)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(pressed ? theme.accent.opacity(0.12) : Color.white.opacity(0.02))
            )
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { pressed = $0 }, perform: {})
    }
}

// MARK: - Settings sheet

struct TerminalSettingsSheet: View {
    @ObservedObject var bridge: TerminalBridge
    let theme: ParadiseTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: theme.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Form {
                    Section("Server") {
                        LabeledContent("Host") {
                            TextField("localhost", text: $bridge.host)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        LabeledContent("Port") {
                            TextField("8765", text: $bridge.port)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }
                    Section("Actions") {
                        Button("Reconnect") {
                            bridge.disconnect()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                bridge.connect()
                                dismiss()
                            }
                        }.foregroundColor(theme.accent)
                    }
                    Section("Quick Commands") {
                        ForEach([
                            "help", "ls -la", "pwd", "files",
                            "python3 --version", "pip list",
                            "node --version", "git --version"
                        ], id: \.self) { cmd in
                            Button(cmd) {
                                bridge.buffer.appendInput("> \(cmd)")
                                bridge.send(command: cmd)
                                dismiss()
                            }
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(theme.textColor)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Terminal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(theme.accent)
                }
            }
        }
    }
}

// MARK: - Button style helper

extension View {
    func termBarButton(color: Color) -> some View {
        self
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.5))
            )
            .buttonStyle(.plain)
    }
}
