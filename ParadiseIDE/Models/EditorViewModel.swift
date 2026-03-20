import SwiftUI
import Combine

// MARK: - Pet Mood

enum PetMood: String {
    case idle, typing, ai, error, happy

    var message: String {
        switch self {
        case .idle:   return ""
        case .typing: return "You're in the flow!"
        case .ai:     return "AI has a tip!"
        case .error:  return "Don't worry, I'm here"
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

// MARK: - File Item

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let type: FileType
    let depth: Int
    enum FileType { case directory, file }
}

// MARK: - IDE Edition

enum IDEEdition: String, CaseIterable {
    case personal   = "Personal"
    case community  = "Community"
    case enterprise = "Enterprise"

    var isFree: Bool { self != .enterprise }
    var price: String { isFree ? "Free forever" : "$99 / year" }
    var badge: String {
        switch self {
        case .personal:   return "Personal"
        case .community:  return "Community"
        case .enterprise: return "Enterprise"
        }
    }
}

// MARK: - Starter Code

let paradiseStarterCode = """
// Welcome to Paradise IDE
// Your stress-free coding sanctuary

import Foundation

func greetParadise(name: String) -> String {
    let message = "Hello, \\(name)!"
    print(message)
    return message
}

// AI Co-Pilot is watching...
// Start typing to feel the flow
greetParadise(name: "World")
"""

// MARK: - EditorViewModel

final class EditorViewModel: ObservableObject {

    @Published var theme: ParadiseTheme = .ocean
    @Published var edition: IDEEdition = .personal
    @Published var performanceMode: Bool = false
    @Published var guideMode: Bool = false

    @Published var code: String
    @Published var selectedFile: String = "main.swift"
    @Published var lineCount: Int = 1
    @Published var column: Int = 1
    @Published var currentLine: Int = 1

    @Published var petMood: PetMood = .idle
    @Published var currentSuggestion: AISuggestion? = nil
    @Published var aiPulsing: Bool = false
    @Published var showErrorToast: Bool = false
    @Published var showExportPanel: Bool = false

    private var typingWorkItem: DispatchWorkItem?

    init() {
        self.code = paradiseStarterCode
    }

    // MARK: - File tree

    let fileTree: [FileItem] = [
        FileItem(name: "paradise-app", type: .directory, depth: 0),
        FileItem(name: "Sources",       type: .directory, depth: 1),
        FileItem(name: "main.swift",    type: .file,      depth: 2),
        FileItem(name: "Pet.swift",     type: .file,      depth: 2),
        FileItem(name: "Copilot.swift", type: .file,      depth: 2),
        FileItem(name: "Themes.swift",  type: .file,      depth: 2),
        FileItem(name: "Export",        type: .directory, depth: 1),
        FileItem(name: "build.yaml",    type: .file,      depth: 2),
        FileItem(name: "Package.swift", type: .file,      depth: 1),
    ]

    // MARK: - AI Suggestions

    private let suggestions: [AISuggestion] = [
        AISuggestion(trigger: "func ",  message: "Nice function! Want to add a doc comment?",      fix: "/// Brief description of what this does.\n"),
        AISuggestion(trigger: "print(", message: "Consider os.log for production-grade logging.",   fix: nil),
        AISuggestion(trigger: "return", message: "Clean return! Code looks great.",                 fix: nil),
        AISuggestion(trigger: "catch",  message: "Error caught. Want a friendly user message?",     fix: "// TODO: show user-facing alert here\n"),
        AISuggestion(trigger: "for ",   message: "Loop detected. Could .map() be cleaner here?",   fix: nil),
        AISuggestion(trigger: "var ",   message: "Consider 'let' for immutable values.",            fix: nil),
        AISuggestion(trigger: "async",  message: "Async detected! Remember await and error handling.", fix: nil),
    ]

    // MARK: - Code editing

    func onCodeChange(_ newValue: String) {
        code = newValue
        lineCount = newValue.components(separatedBy: "\n").count

        petMood = .typing

        typingWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.petMood = .idle }
        typingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)

        let tail = String(newValue.suffix(120)).lowercased()
        for suggestion in suggestions {
            if tail.contains(suggestion.trigger) {
                triggerAISuggestion(suggestion)
                return
            }
        }
    }

    private func triggerAISuggestion(_ suggestion: AISuggestion) {
        currentSuggestion = suggestion
        aiPulsing = true
        petMood = .ai
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
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

    func dismissSuggestion() {
        currentSuggestion = nil
    }

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
