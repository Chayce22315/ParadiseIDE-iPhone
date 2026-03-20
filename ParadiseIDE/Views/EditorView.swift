import SwiftUI

// MARK: - Syntax Highlighter
// Tokenises Swift/Python/JS and returns an AttributedString.

struct SyntaxHighlighter {

    enum Language { case swift_, python, javascript, yaml, plain }

    struct Token { let text: String; let color: Color }

    static func language(for filename: String) -> Language {
        switch (filename as NSString).pathExtension.lowercased() {
        case "swift":       return .swift_
        case "py":          return .python
        case "js", "ts":    return .javascript
        case "yaml", "yml": return .yaml
        default:            return .plain
        }
    }

    // ── Swift keywords ──────────────────────────────────────
    static let swiftKeywords: Set<String> = [
        "func","var","let","class","struct","enum","protocol","extension",
        "import","return","if","else","guard","switch","case","default",
        "for","while","repeat","break","continue","in","where","throw",
        "throws","try","catch","async","await","self","super","true","false",
        "nil","static","final","override","private","public","internal",
        "fileprivate","open","lazy","weak","unowned","mutating","some","any",
        "init","deinit","subscript","typealias","associatedtype","inout"
    ]
    static let pythonKeywords: Set<String> = [
        "def","class","import","from","return","if","elif","else","for",
        "while","with","as","try","except","finally","raise","pass","break",
        "continue","in","not","and","or","is","lambda","yield","async","await",
        "True","False","None","global","nonlocal","del","print"
    ]

    // Tokenise a single line for Swift
    static func tokenise(line: String, lang: Language, theme: ParadiseTheme) -> [Token] {
        var tokens: [Token] = []
        var buf = ""

        let kw    = theme.accent
        let str_  = Color(red: 0.9, green: 0.6, blue: 0.4)
        let cmnt  = theme.mutedColor
        let num   = Color(red: 0.7, green: 0.9, blue: 0.5)
        let sym   = theme.accent.opacity(0.7)
        let plain = theme.textColor

        func flush(_ color: Color = plain) {
            if !buf.isEmpty { tokens.append(Token(text: buf, color: color)); buf = "" }
        }

        var i = line.startIndex
        while i < line.endIndex {
            let ch = line[i]

            // Comment
            if (lang == .swift_ || lang == .javascript) && ch == "/" && line.index(after: i) < line.endIndex {
                let next = line[line.index(after: i)]
                if next == "/" {
                    flush()
                    tokens.append(Token(text: String(line[i...]), color: cmnt))
                    return tokens
                }
            }
            if lang == .python && ch == "#" {
                flush()
                tokens.append(Token(text: String(line[i...]), color: cmnt))
                return tokens
            }

            // String literal
            if ch == "\"" || ch == "'" {
                flush()
                let quote = ch
                var s = String(ch)
                i = line.index(after: i)
                while i < line.endIndex {
                    s.append(line[i])
                    if line[i] == quote { i = line.index(after: i); break }
                    i = line.index(after: i)
                }
                tokens.append(Token(text: s, color: str_))
                continue
            }

            // Number
            if ch.isNumber {
                flush()
                var n = ""
                while i < line.endIndex && (line[i].isNumber || line[i] == ".") {
                    n.append(line[i]); i = line.index(after: i)
                }
                tokens.append(Token(text: n, color: num))
                continue
            }

            // Identifier or keyword
            if ch.isLetter || ch == "_" {
                flush()
                var word = ""
                while i < line.endIndex && (line[i].isLetter || line[i].isNumber || line[i] == "_") {
                    word.append(line[i]); i = line.index(after: i)
                }
                let isKW: Bool = {
                    switch lang {
                    case .swift_:      return swiftKeywords.contains(word)
                    case .python:      return pythonKeywords.contains(word)
                    default:           return false
                    }
                }()
                tokens.append(Token(text: word, color: isKW ? kw : plain))
                continue
            }

            // Symbol
            if "{}[]()=<>!&|+-*/%.,;:@#".contains(ch) {
                flush()
                tokens.append(Token(text: String(ch), color: sym))
                i = line.index(after: i)
                continue
            }

            buf.append(ch)
            i = line.index(after: i)
        }
        flush()
        return tokens
    }
}

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 0) {
            EditorTabBar()
            if vm.guideMode { GuideBannerView().transition(.move(edge: .top).combined(with: .opacity)) }

            HStack(spacing: 0) {
                LineGutter()          // Interactive line numbers
                    .frame(width: 44)
                CodeEditorPane()      // TextEditor + AI popup
            }

            EditorToolbarView()
        }
        .background(Color.black.opacity(0.12))
        .animation(.spring(response: 0.3), value: vm.guideMode)
    }
}

// MARK: - Tab bar

struct EditorTabBar: View {
    @EnvironmentObject var vm: EditorViewModel
    private let tabs = ["main.swift", "Pet.swift", "build.yaml"]
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button { vm.selectedFile = tab } label: {
                    HStack(spacing: 5) {
                        Text(tabIcon(tab)).font(.system(size: 11))
                        Text(tab)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(vm.selectedFile == tab ? t.accent : t.mutedColor)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(vm.selectedFile == tab ? t.accent.opacity(0.10) : Color.clear)
                    .overlay(
                        Rectangle().frame(height: 1.5).foregroundColor(vm.selectedFile == tab ? t.accent : .clear),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button { withAnimation { vm.guideMode.toggle() } } label: {
                Text("🧭 GUIDE")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(vm.guideMode ? t.accent : t.mutedColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(vm.guideMode ? t.accent.opacity(0.15) : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(vm.guideMode ? t.accent : t.surfaceBorder, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain).padding(.trailing, 10)

            VirtualPetView().padding(.trailing, 12)
        }
        .frame(height: 36)
        .background(t.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }

    private func tabIcon(_ name: String) -> String {
        switch (name as NSString).pathExtension {
        case "swift": return "🔷"
        case "yaml":  return "⚙️"
        default:      return "📄"
        }
    }
}

// MARK: - Guide banner

struct GuideBannerView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }
    var body: some View {
        HStack(spacing: 8) {
            Text("🧭")
            Text("Guide Mode — Next: define your main function and call it with a test argument. AI will highlight suggestions as you type.")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(t.textColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.accent.opacity(0.10))
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .bottom)
    }
}

// MARK: - Line gutter (shows line numbers, highlights current line)

struct LineGutter: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(1, vm.lineCount), id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(n == vm.currentLine ? t.accent : t.mutedColor.opacity(0.6))
                        .frame(height: 20, alignment: .trailing)
                        .padding(.trailing, 8)
                        .background(n == vm.currentLine ? t.accent.opacity(0.06) : Color.clear)
                }
            }
            .padding(.top, 14)
        }
        .background(Color.black.opacity(0.15))
        .overlay(Rectangle().frame(width: 1).foregroundColor(t.surfaceBorder), alignment: .trailing)
        .disabled(true)
    }
}

// MARK: - Code editor pane

struct CodeEditorPane: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: Binding(
                get: { vm.code },
                set: { vm.onCodeChange($0) }
            ))
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(t.textColor)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(.leading, 10).padding(.top, 10)
            .tint(t.accent)

            // AI suggestion popup
            if let suggestion = vm.currentSuggestion {
                AISuggestionPanel(suggestion: suggestion)
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35), value: vm.currentSuggestion != nil)
            }
        }
    }
}

// MARK: - AI suggestion panel

struct AISuggestionPanel: View {
    @EnvironmentObject var vm: EditorViewModel
    let suggestion: AISuggestion
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🤖 AI CO-PILOT")
                .font(.system(size: 9, design: .monospaced)).foregroundColor(t.mutedColor).tracking(1)

            Text(suggestion.message)
                .font(.system(size: 12, design: .monospaced)).foregroundColor(t.textColor).lineSpacing(4)

            HStack(spacing: 8) {
                if suggestion.fix != nil {
                    Button("✦ Apply Fix") { vm.applyFix() }
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(t.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(t.accent.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1)))
                        .buttonStyle(.plain)
                }
                Button("Dismiss") { vm.dismissSuggestion() }
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.mutedColor)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
                    .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(t.surface)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: t.accent.opacity(0.25), radius: 20, x: 0, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.accent.opacity(0.5), lineWidth: 1))
        .frame(maxWidth: 280)
    }
}

// MARK: - Bottom toolbar

struct EditorToolbarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 10) {
            Button { vm.triggerErrorToast() } label: {
                Text("🤖 AI Tools")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.accent)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(t.accent.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .shadow(color: vm.aiPulsing ? t.accent.opacity(0.7) : .clear, radius: vm.aiPulsing ? 14 : 0)
            .animation(
                vm.aiPulsing && !vm.performanceMode
                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                : .default,
                value: vm.aiPulsing
            )

            Button { vm.showExportPanel = true } label: {
                Text("⚙️ Export")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(t.mutedColor)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
            }.buttonStyle(.plain)

            Spacer()

            Text("🎵 \(t.ambientLabel)")
                .font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)

            HStack(spacing: 6) {
                Circle().fill(t.accent).frame(width: 7, height: 7)
                    .shadow(color: t.accent.opacity(0.8), radius: vm.performanceMode ? 2 : 6)
                    .animation(vm.performanceMode ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: vm.performanceMode)
                Text("Flow State Active")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(t.accent)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(t.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(t.surfaceBorder), alignment: .top)
    }
}
