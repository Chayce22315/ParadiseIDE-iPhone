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
    @Published var findText: String = ""
    @Published var replaceText: String = ""

    // AI response
    @Published var aiResponse: String = ""
    @Published var showAIPanel: Bool = false

    private var typingWorkItem: DispatchWorkItem?

    // Current active tab code
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

    // MARK: - Tab management

    func openFile(url: URL, content: String, language: String) {
        // Check if already open
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
        let ext = language == "python" ? "py" : language == "javascript" ? "js" : "swift"
        let name = "untitled.\(ext)"
        let tab = OpenTab(url: nil, name: name, content: "", isDirty: false, language: language)
        tabs.append(tab)
        activeTabID = tab.id
        selectedFile = name
    }

    func closeTab(_ tab: OpenTab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: idx)
        if activeTabID == tab.id {
            activeTabID = tabs.last?.id
        }
    }

        @MainActor func saveActiveTab(using folderManager: FolderManager) {
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

    // MARK: - AI Suggestions

    private let suggestions: [AISuggestion] = [
        AISuggestion(trigger: "func ",  message: "Nice function! Add a doc comment?",      fix: "/// Brief description.\n"),
        AISuggestion(trigger: "print(", message: "Consider os.log for production.",         fix: nil),
        AISuggestion(trigger: "catch",  message: "Error caught. Add user-facing message?",  fix: "// TODO: show alert\n"),
        AISuggestion(trigger: "for ",   message: "Loop detected. Could .map() be cleaner?", fix: nil),
        AISuggestion(trigger: "var ",   message: "Consider 'let' if value won't change.",   fix: nil),
        AISuggestion(trigger: "async",  message: "Remember await and error handling.",       fix: nil),
        AISuggestion(trigger: "TODO",   message: "You have a TODO here — want help with it?",fix: nil),
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
