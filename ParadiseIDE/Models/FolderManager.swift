import SwiftUI
import UniformTypeIdentifiers

// MARK: - File Node

class FileNode: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    @Published var children: [FileNode]?
    @Published var isExpanded: Bool = false

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        if self.isDirectory { self.children = [] }
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "swift":                    return "swift"
        case "py":                       return "terminal.fill"
        case "js", "mjs", "cjs":        return "j.square"
        case "ts", "tsx":                return "t.square"
        case "jsx":                      return "atom"
        case "json":                     return "curlybraces"
        case "yaml", "yml":              return "gearshape"
        case "md", "mdx":               return "doc.text"
        case "html", "htm":             return "globe"
        case "css", "scss", "sass":     return "paintbrush"
        case "sh", "bash", "zsh":       return "terminal"
        case "zip", "tar", "gz":        return "archivebox"
        case "png","jpg","jpeg","gif","webp","svg": return "photo"
        case "rs":                       return "r.square"
        case "go":                       return "g.square"
        case "rb":                       return "diamond"
        case "java", "kt", "kts":       return "j.circle"
        case "c", "h":                   return "c.square"
        case "cpp", "cc", "cxx", "hpp": return "plus.square"
        case "cs":                       return "number.square"
        case "php":                      return "p.square"
        case "lua":                      return "l.square"
        case "sql":                      return "cylinder"
        case "xml":                      return "chevron.left.forwardslash.chevron.right"
        case "toml", "ini", "cfg":      return "gearshape.2"
        case "env":                      return "lock.doc"
        case "dockerfile":              return "shippingbox"
        case "ipa", "apk", "exe":       return "app.badge"
        default:                         return "doc"
        }
    }

    var language: String {
        switch url.lastPathComponent.lowercased() {
        case "dockerfile": return "dockerfile"
        case "makefile":   return "makefile"
        case ".env", ".env.example": return "env"
        default: break
        }
        switch url.pathExtension.lowercased() {
        case "swift":                    return "swift"
        case "py", "pyw":               return "python"
        case "js", "mjs", "cjs":        return "javascript"
        case "ts":                       return "typescript"
        case "tsx":                      return "tsx"
        case "jsx":                      return "jsx"
        case "json", "jsonc":           return "json"
        case "yaml", "yml":             return "yaml"
        case "toml":                     return "toml"
        case "md", "mdx":               return "markdown"
        case "html", "htm":             return "html"
        case "css":                      return "css"
        case "scss":                     return "scss"
        case "sass":                     return "sass"
        case "sh", "bash", "zsh":       return "shell"
        case "rs":                       return "rust"
        case "go":                       return "go"
        case "rb":                       return "ruby"
        case "java":                     return "java"
        case "kt", "kts":               return "kotlin"
        case "c", "h":                   return "c"
        case "cpp","cc","cxx","hpp":    return "cpp"
        case "cs":                       return "csharp"
        case "php":                      return "php"
        case "lua":                      return "lua"
        case "sql":                      return "sql"
        case "r":                        return "r"
        case "dart":                     return "dart"
        case "ex", "exs":               return "elixir"
        case "erl", "hrl":              return "erlang"
        case "hs":                       return "haskell"
        case "ml", "mli":               return "ocaml"
        case "clj", "cljs":             return "clojure"
        case "scala":                    return "scala"
        case "groovy":                   return "groovy"
        case "pl", "pm":                return "perl"
        case "xml", "plist":            return "xml"
        case "ini", "cfg", "conf":      return "ini"
        case "env":                      return "env"
        case "dockerfile":              return "dockerfile"
        case "tf", "tfvars":            return "terraform"
        case "proto":                    return "protobuf"
        case "graphql", "gql":          return "graphql"
        case "vue":                      return "vue"
        case "svelte":                   return "svelte"
        case "txt", "log":              return "text"
        default:                         return "text"
        }
    }
}

// MARK: - FolderManager

@MainActor
final class FolderManager: ObservableObject {
    @Published var rootNode: FileNode? = nil
    @Published var rootURL: URL? = nil
    @Published var rootName: String = "No folder"
    @Published var showPicker: Bool = false
    @Published var errorMessage: String? = nil
    @Published var totalFileCount: Int = 0
    @Published var commitCount: Int = 0

    private let bookmarkKey = "paradise.folderBookmark.v3"

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var paradiseDocumentsURL: URL {
        let url = documentsURL.appendingPathComponent("Paradise IDE", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    init() {
        restoreBookmark()
    }

    // MARK: - Open folder (called from picker delegate)

    func openFolder(_ url: URL) {
        // Must call startAccessingSecurityScopedResource on the URL from the picker
        let accessing = url.startAccessingSecurityScopedResource()
        print("Paradise: openFolder called with \(url.path), accessing=\(accessing)")

        saveBookmark(url, accessing: accessing)
        loadFolder(url)
    }

    private func loadFolder(_ url: URL) {
        rootURL = url
        rootName = url.lastPathComponent
        let node = FileNode(url: url)
        loadChildren(of: node)
        node.isExpanded = true
        rootNode = node
        totalFileCount = countFiles(in: url)
        print("Paradise: loaded folder \(url.path) with \(node.children?.count ?? 0) items, \(totalFileCount) total files")
    }

    func loadChildren(of node: FileNode) {
        guard node.isDirectory else { return }
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(
            at: node.url,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("Paradise: cannot read directory \(node.url.path)")
            return
        }

        let sorted = contents.sorted {
            let aIsDir = (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bIsDir = (try? $1.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if aIsDir != bIsDir { return aIsDir }
            return $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased()
        }

        node.children = sorted.map { FileNode(url: $0) }
    }

    func refresh() {
        guard let url = rootURL else { return }
        loadFolder(url)
    }

    func countFiles(in url: URL) -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var count = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
               values.isRegularFile == true {
                count += 1
            }
        }
        return count
    }

    func countSaveActions() {
        commitCount += 1
    }

    func clearFolder() {
        rootURL?.stopAccessingSecurityScopedResource()
        rootNode = nil
        rootURL = nil
        rootName = "No folder"
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // MARK: - File operations

    func readFile(_ url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try latin1 as fallback
            return try? String(contentsOf: url, encoding: .isoLatin1)
        }
    }

    func writeFile(_ url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func createFile(in directory: URL, name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        refresh()
        return url
    }

    func createFolder(in directory: URL, name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        refresh()
        return url
    }

    func deleteItem(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
        refresh()
    }

    func renameItem(_ url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: newURL)
        refresh()
        return newURL
    }

    // MARK: - Bookmark

    private func saveBookmark(_ url: URL, accessing: Bool) {
        let opts: URL.BookmarkCreationOptions = accessing ? .minimalBookmark : .minimalBookmark
        guard let data = try? url.bookmarkData(
            options: opts,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    private func restoreBookmark() {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return }
        if stale { print("Paradise: bookmark stale, re-saving") }
        _ = url.startAccessingSecurityScopedResource()
        loadFolder(url)
    }

    // MARK: - Documents

    func listDocuments() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: Self.paradiseDocumentsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? []
    }
}

// MARK: - Folder Picker

struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: (() -> Void)?

    init(onPick: @escaping (URL) -> Void, onCancel: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        } else {
            picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        }
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: (() -> Void)?

        init(onPick: @escaping (URL) -> Void, onCancel: (() -> Void)?) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            print("Paradise: picker selected \(url.path)")
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Paradise: picker cancelled")
            onCancel?()
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
