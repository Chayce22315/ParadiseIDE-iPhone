import SwiftUI
import Combine

// MARK: - InputHistory
// Manages up/down arrow command history, exactly like a real shell.

final class InputHistory: ObservableObject {
    private var history: [String] = []
    private var index: Int = -1
    private var draft: String = ""   // saves what user typed before ↑

    func push(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Don't duplicate consecutive identical commands
        if history.first != trimmed { history.insert(trimmed, at: 0) }
        if history.count > 200 { history.removeLast() }
        index = -1
        draft = ""
    }

    func up(current: String) -> String {
        if index == -1 { draft = current }
        let next = min(index + 1, history.count - 1)
        guard next < history.count else { return current }
        index = next
        return history[index]
    }

    func down() -> String {
        guard index > -1 else { return "" }
        index -= 1
        return index == -1 ? draft : history[index]
    }

    func reset() { index = -1; draft = "" }

    var all: [String] { history }
}

// MARK: - AutocompleteEngine
// Simple prefix-based autocomplete for common shell/paradise commands.
// Extend completions or hook into the server's `ls` output for path completion.

final class AutocompleteEngine: ObservableObject {
    @Published var suggestions: [String] = []
    @Published var isVisible: Bool = false

    private let builtins = [
        "help", "clear", "files", "pwd", "ls", "ls -la",
        "cd ", "cat ", "rm ", "download ",
        "python3 ", "python3 --version",
        "pip install ", "pip list", "pip freeze",
        "node ", "node --version",
        "git clone ", "git status", "git log", "git diff",
        "curl ", "wget ",
        "make", "cmake",
        "zip ", "unzip ",
        "echo ", "env", "export ",
        "exit", "quit",
    ]

    func update(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { suggestions = []; isVisible = false; return }

        let matches = builtins.filter { $0.hasPrefix(trimmed) && $0 != trimmed }
        suggestions = Array(matches.prefix(6))
        isVisible = !suggestions.isEmpty
    }

    func accept(_ suggestion: String) {
        isVisible = false
    }

    func hide() { isVisible = false }
}
