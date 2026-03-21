import SwiftUI
import UniformTypeIdentifiers

// MARK: - File Node (real filesystem item)

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
        if self.isDirectory {
            self.children = []
        }
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        switch url.pathExtension.lowercased() {
        case "swift":        return "swift"
        case "py":           return "terminal.fill"
        case "js", "ts":     return "j.square"
        case "json":         return "curlybraces"
        case "yaml", "yml":  return "gearshape"
        case "md":           return "doc.text"
        case "html":         return "globe"
        case "css":          return "paintbrush"
        case "sh":           return "terminal"
        case "zip", "tar":   return "archivebox"
        case "png","jpg","jpeg","gif","webp": return "photo"
        default:             return "doc"
        }
    }

    var language: String {
        switch url.pathExtension.lowercased() {
        case "swift":    return "swift"
        case "py":       return "python"
        case "js","ts":  return "javascript"
        case "json":     return "json"
        case "yaml","yml": return "yaml"
        case "html":     return "html"
        case "css":      return "css"
        case "md":       return "markdown"
        case "sh":       return "shell"
        default:         return "text"
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

    private let bookmarkKey = "paradise.folderBookmark.v2"

    // App Documents folder — visible in Files app
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

    // MARK: - Open folder

    func openFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            // Try without security scope (for app's own Documents)
            loadFolder(url)
            return
        }
        saveBookmark(url)
        loadFolder(url)
    }

    private func loadFolder(_ url: URL) {
        rootURL = url
        rootName = url.lastPathComponent
        let node = FileNode(url: url)
        loadChildren(of: node)
        rootNode = node
        node.isExpanded = true
    }

    func loadChildren(of node: FileNode) {
        guard node.isDirectory else { return }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: node.url,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) else { return }

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

    func clearFolder() {
        rootNode?.url.stopAccessingSecurityScopedResource()
        rootNode = nil
        rootURL = nil
        rootName = "No folder"
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // MARK: - File operations

    func readFile(_ url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }

    func writeFile(_ url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func createFile(in directory: URL, name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try "".write(to: url, atomically: true, encoding: .utf8)
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

    private func saveBookmark(_ url: URL) {
        guard let data = try? url.bookmarkData(
            options: .minimalBookmark,
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
        if stale { saveBookmark(url) }
        _ = url.startAccessingSecurityScopedResource()
        loadFolder(url)
    }

    // MARK: - Documents browser

    func listDocuments() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: Self.paradiseDocumentsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? []
    }

    func exportToDocuments(text: String, filename: String) throws -> URL {
        let dest = Self.paradiseDocumentsURL.appendingPathComponent(filename)
        try text.write(to: dest, atomically: true, encoding: .utf8)
        return dest
    }
}

// MARK: - Folder Picker

struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
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
