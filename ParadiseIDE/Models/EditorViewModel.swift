import SwiftUI
import Combine

// MARK: - Pet Mood

enum PetMood: String {
    case idle, typing, ai, error, happy
    var message: String {
        switch self {
        case .idle:   return ""
        case .typing: return "In the flow!"
        case .ai:     return "AI has a tip!"
        case .error:  return "Don't worry!"
        case .happy:  return "Great code!"
        }
    }
}

// MARK: - AI Suggestion

struct AISuggestion: Identifiable {
    let id = UUID()
    let trigger: String
    let message: String
    let fix: String?
}

// MARK: - Open Tab

struct OpenTab: Identifiable, Equatable {
    let id = UUID()
    var url: URL?
    var name: String
    var content: String
    var isDirty: Bool = false
    var language: String = "swift"

    static func == (lhs: OpenTab, rhs: OpenTab) -> Bool { lhs.id == rhs.id }
}

// MARK: - IDE Edition

enum IDEEdition: String, CaseIterable {
    case personal = "Personal"
    case community = "Community"
    case enterprise = "Enterprise"
    var isFree: Bool { self != .enterprise }
    var price: String { isFree ? "Free forever" : "$99/yr" }
    var badge: String {
        switch self {
        case .personal:   return "Personal"
        case .community:  return "Community"
        case .enterprise: return "Enterprise"
        }
    }
}

// MARK: - Code Snippet

struct CodeSnippet: Identifiable {
    let id = UUID()
    let name: String
    let language: String
    let icon: String
    let code: String
    let description: String
}

// MARK: - EditorViewModel

final class EditorViewModel: ObservableObject {

    // Theme & edition
    @Published var theme: ParadiseTheme = .ocean
    @Published var edition: IDEEdition = .personal
    @Published var performanceMode: Bool = false
    @Published var guideMode: Bool = false

    // Tabs
    @Published var tabs: [OpenTab] = []
    @Published var activeTabID: UUID? = nil

    // Legacy single-file state (for compatibility)
    @Published var selectedFile: String = "untitled.swift"
    @Published var lineCount: Int = 1
    @Published var column: Int = 1
    @Published var currentLine: Int = 1

    // Pet
    @Published var petMood: PetMood = .idle
    @Published var currentSuggestion: AISuggestion? = nil
    @Published var aiPulsing: Bool = false

    // UI
    @Published var showErrorToast: Bool = false
    @Published var showExportPanel: Bool = false
    @Published var showFindReplace: Bool = false
    @Published var showSettingsPanel: Bool = false
    @Published var showSnippetsPanel: Bool = false
    @Published var findText: String = ""
    @Published var replaceText: String = ""

    // AI response
    @Published var aiResponse: String = ""
    @Published var showAIPanel: Bool = false

    // Settings
    @Published var editorFontSize: CGFloat = 14
    @Published var showLineNumbers: Bool = true
    @Published var autoSave: Bool = false
    @Published var wordWrap: Bool = true

    private var typingWorkItem: DispatchWorkItem?

    var code: String {
        get { activeTab?.content ?? "" }
        set {
            guard let id = activeTabID,
                  let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
            tabs[idx].content = newValue
            tabs[idx].isDirty = true
            onCodeChange(newValue)
        }
    }

    var activeTab: OpenTab? {
        guard let id = activeTabID else { return nil }
        return tabs.first(where: { $0.id == id })
    }

    // MARK: - Snippets library

    let snippets: [CodeSnippet] = [
        CodeSnippet(
            name: "SwiftUI View",
            language: "swift",
            icon: "rectangle.3.group",
            code: """
            struct MyView: View {
                var body: some View {
                    VStack {
                        Text("Hello, World!")
                            .font(.title)
                    }
                    .padding()
                }
            }
            """,
            description: "Basic SwiftUI view template"
        ),
        CodeSnippet(
            name: "Async Function",
            language: "swift",
            icon: "arrow.triangle.2.circlepath",
            code: """
            func fetchData() async throws -> Data {
                let url = URL(string: "https://api.example.com/data")!
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            """,
            description: "Swift async/await network request"
        ),
        CodeSnippet(
            name: "Observable Class",
            language: "swift",
            icon: "eye",
            code: """
            @MainActor
            final class MyViewModel: ObservableObject {
                @Published var items: [String] = []
                @Published var isLoading = false
                
                func load() async {
                    isLoading = true
                    defer { isLoading = false }
                    // Load items here
                }
            }
            """,
            description: "ObservableObject view model"
        ),
        CodeSnippet(
            name: "Python Flask",
            language: "python",
            icon: "flask",
            code: """
            from flask import Flask, jsonify, request
            
            app = Flask(__name__)
            
            @app.route('/api/hello', methods=['GET'])
            def hello():
                name = request.args.get('name', 'World')
                return jsonify({"message": f"Hello, {name}!"})
            
            if __name__ == '__main__':
                app.run(debug=True, port=5000)
            """,
            description: "Flask API starter"
        ),
        CodeSnippet(
            name: "HTML Boilerplate",
            language: "html",
            icon: "globe",
            code: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>My App</title>
                <style>
                    body { font-family: system-ui; margin: 0; padding: 2rem; }
                </style>
            </head>
            <body>
                <h1>Hello, World!</h1>
            </body>
            </html>
            """,
            description: "HTML5 starter template"
        ),
        CodeSnippet(
            name: "React Component",
            language: "jsx",
            icon: "atom",
            code: """
            import React, { useState, useEffect } from 'react';
            
            export default function MyComponent({ title }) {
                const [data, setData] = useState(null);
                
                useEffect(() => {
                    fetch('/api/data')
                        .then(res => res.json())
                        .then(setData);
                }, []);
                
                return (
                    <div className="container">
                        <h1>{title}</h1>
                        {data ? <pre>{JSON.stringify(data, null, 2)}</pre> : <p>Loading...</p>}
                    </div>
                );
            }
            """,
            description: "React functional component with hooks"
        ),
        CodeSnippet(
            name: "Rust Struct",
            language: "rust",
            icon: "gearshape.2",
            code: """
            #[derive(Debug, Clone)]
            struct Config {
                name: String,
                port: u16,
                debug: bool,
            }
            
            impl Config {
                fn new(name: &str, port: u16) -> Self {
                    Self {
                        name: name.to_string(),
                        port,
                        debug: false,
                    }
                }
            }
            """,
            description: "Rust struct with impl block"
        ),
        CodeSnippet(
            name: "Go HTTP Server",
            language: "go",
            icon: "server.rack",
            code: """
            package main
            
            import (
                "fmt"
                "net/http"
            )
            
            func handler(w http.ResponseWriter, r *http.Request) {
                fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
            }
            
            func main() {
                http.HandleFunc("/", handler)
                fmt.Println("Server running on :8080")
                http.ListenAndServe(":8080", nil)
            }
            """,
            description: "Go HTTP server starter"
        ),
    ]

    // MARK: - Tab management

    func openFile(url: URL, content: String, language: String) {
        if let existing = tabs.first(where: { $0.url == url }) {
            activeTabID = existing.id
            return
        }
        let tab = OpenTab(
            url: url,
            name: url.lastPathComponent,
            content: content,
            isDirty: false,
            language: language
        )
        tabs.append(tab)
        activeTabID = tab.id
        selectedFile = url.lastPathComponent
        lineCount = content.components(separatedBy: "\n").count
    }

    func newUntitledTab(language: String = "swift") {
        let extMap: [String: String] = [
            "python": "py", "javascript": "js", "typescript": "ts",
            "jsx": "jsx", "tsx": "tsx", "rust": "rs", "go": "go",
            "ruby": "rb", "java": "java", "kotlin": "kt", "c": "c",
            "cpp": "cpp", "csharp": "cs", "php": "php", "lua": "lua",
            "sql": "sql", "shell": "sh", "html": "html", "css": "css",
            "json": "json", "yaml": "yml", "markdown": "md",
            "dart": "dart", "scala": "scala", "r": "r",
            "elixir": "ex", "haskell": "hs",
        ]
        let ext = extMap[language] ?? "swift"
        let name = "untitled.\(ext)"
        let tab = OpenTab(url: nil, name: name, content: "", isDirty: false, language: language)
        tabs.append(tab)
        activeTabID = tab.id
        selectedFile = name
    }

    func newTabFromSnippet(_ snippet: CodeSnippet) {
        let extMap: [String: String] = [
            "swift": "swift", "python": "py", "javascript": "js",
            "html": "html", "jsx": "jsx", "rust": "rs", "go": "go",
        ]
        let ext = extMap[snippet.language] ?? "txt"
        let name = "\(snippet.name.lowercased().replacingOccurrences(of: " ", with: "_")).\(ext)"
        let tab = OpenTab(url: nil, name: name, content: snippet.code, isDirty: true, language: snippet.language)
        tabs.append(tab)
        activeTabID = tab.id
        selectedFile = name
        lineCount = snippet.code.components(separatedBy: "\n").count
    }

    func closeTab(_ tab: OpenTab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: idx)
        if activeTabID == tab.id {
            activeTabID = tabs.last?.id
        }
    }

    func saveActiveTab(using folderManager: FolderManager) {
        guard let id = activeTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs[idx]
        if let url = tab.url {
            try? folderManager.writeFile(url, content: tab.content)
            tabs[idx].isDirty = false
            petMood = .happy
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.petMood = .idle
            }
        }
    }

    // MARK: - Code actions

    func formatCode() {
        guard let id = activeTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        var lines = tabs[idx].content.components(separatedBy: "\n")
        lines = lines.map { $0.replacingOccurrences(of: "\t", with: "    ") }
        while lines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true && lines.count > 1 {
            lines.removeLast()
        }
        tabs[idx].content = lines.joined(separator: "\n")
        tabs[idx].isDirty = true
    }

    func duplicateCurrentLine() {
        guard let id = activeTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        var lines = tabs[idx].content.components(separatedBy: "\n")
        let targetLine = min(currentLine - 1, lines.count - 1)
        if targetLine >= 0 && targetLine < lines.count {
            lines.insert(lines[targetLine], at: targetLine + 1)
            tabs[idx].content = lines.joined(separator: "\n")
            tabs[idx].isDirty = true
            lineCount = lines.count
        }
    }

    func toggleComment() {
        guard let id = activeTabID,
              let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        var lines = tabs[idx].content.components(separatedBy: "\n")
        let lang = tabs[idx].language
        let commentPrefix: String
        switch lang {
        case "python", "ruby", "shell", "r": commentPrefix = "# "
        case "html": commentPrefix = "<!-- "
        case "css", "scss": commentPrefix = "/* "
        default: commentPrefix = "// "
        }

        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(commentPrefix) {
                lines[i] = lines[i].replacingOccurrences(of: commentPrefix, with: "", options: [], range: lines[i].range(of: commentPrefix))
            } else if !trimmed.isEmpty {
                let leadingSpaces = lines[i].prefix(while: { $0 == " " || $0 == "\t" })
                lines[i] = leadingSpaces + commentPrefix + lines[i].trimmingCharacters(in: .whitespaces)
            }
        }

        tabs[idx].content = lines.joined(separator: "\n")
        tabs[idx].isDirty = true
    }

    // MARK: - AI Suggestions

    private let suggestions: [AISuggestion] = [
        AISuggestion(trigger: "func ",  message: "Nice function! Add a doc comment?",      fix: "/// Brief description.\n"),
        AISuggestion(trigger: "print(", message: "Consider os.log for production.",         fix: nil),
        AISuggestion(trigger: "catch",  message: "Error caught. Add user-facing message?",  fix: "// TODO: show alert\n"),
        AISuggestion(trigger: "for ",   message: "Loop detected. Could .map() be cleaner?", fix: nil),
        AISuggestion(trigger: "var ",   message: "Consider 'let' if value won't change.",   fix: nil),
        AISuggestion(trigger: "async",  message: "Remember await and error handling.",       fix: nil),
        AISuggestion(trigger: "TODO",   message: "You have a TODO here -- want help with it?",fix: nil),
    ]

    func onCodeChange(_ newValue: String) {
        lineCount = newValue.components(separatedBy: "\n").count
        petMood = .typing

        typingWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.petMood = .idle }
        typingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)

        let tail = String(newValue.suffix(120)).lowercased()
        for suggestion in suggestions {
            if tail.contains(suggestion.trigger.lowercased()) {
                triggerAISuggestion(suggestion)
                return
            }
        }
    }

    private func triggerAISuggestion(_ suggestion: AISuggestion) {
        currentSuggestion = suggestion
        aiPulsing = true
        petMood = .ai
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.aiPulsing = false
        }
    }

    func applyFix() {
        if let fix = currentSuggestion?.fix {
            code = fix + code
            petMood = .happy
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.petMood = .idle
            }
        }
        currentSuggestion = nil
    }

    func dismissSuggestion() { currentSuggestion = nil }

    func triggerErrorToast() {
        showErrorToast = true
        aiPulsing = true
        petMood = .error
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.aiPulsing = false
            self?.petMood = .idle
        }
    }

    func petTapped() {
        petMood = petMood == .happy ? .idle : .happy
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.petMood == .happy { self?.petMood = .idle }
        }
    }
}
