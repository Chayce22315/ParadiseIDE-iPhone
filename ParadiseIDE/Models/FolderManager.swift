import SwiftUI
import UniformTypeIdentifiers

// MARK: - FolderManager
// Handles:
//  - Picking a project folder from anywhere on the device
//  - Persisting the bookmark across app launches
//  - Exporting files to the app's Documents folder (visible in Files app)
//  - Saving temp/update files into Documents/Paradise IDE/

@MainActor
final class FolderManager: ObservableObject {

    @Published var currentFolderURL: URL? = nil
    @Published var currentFolderName: String = "No folder selected"
    @Published var recentFolders: [URL] = []

    private let bookmarkKey = "paradise.folderBookmark"
    private let recentKey   = "paradise.recentFolders"

    // App's Documents folder — visible in Files app
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Paradise IDE subfolder inside Documents
    static var paradiseDocumentsURL: URL {
        let url = documentsURL.appendingPathComponent("Paradise IDE", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    init() {
        restoreBookmark()
        loadRecentFolders()
    }

    // MARK: - Set folder

    func setFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        currentFolderURL  = url
        currentFolderName = url.lastPathComponent
        saveBookmark(url)
        addToRecent(url)
    }

    func clearFolder() {
        currentFolderURL?.stopAccessingSecurityScopedResource()
        currentFolderURL  = nil
        currentFolderName = "No folder selected"
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // MARK: - Export to Documents

    /// Copy a file into Documents/Paradise IDE/ so it shows in Files app
    func exportToDocuments(from sourceURL: URL, filename: String? = nil) throws -> URL {
        let dest = Self.paradiseDocumentsURL
            .appendingPathComponent(filename ?? sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        return dest
    }

    /// Write raw data directly to Documents/Paradise IDE/
    func writeToDocuments(data: Data, filename: String) throws -> URL {
        let dest = Self.paradiseDocumentsURL.appendingPathComponent(filename)
        try data.write(to: dest)
        return dest
    }

    /// Write a string file to Documents/Paradise IDE/
    func writeToDocuments(text: String, filename: String) throws -> URL {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return try writeToDocuments(data: data, filename: filename)
    }

    // MARK: - List Documents/Paradise IDE/ contents

    func listDocuments() -> [URL] {
        let url = Self.paradiseDocumentsURL
        return (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
    }

    // MARK: - Bookmark persistence

    private func saveBookmark(_ url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
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
        if url.startAccessingSecurityScopedResource() {
            currentFolderURL  = url
            currentFolderName = url.lastPathComponent
        }
    }

    // MARK: - Recent folders

    private func addToRecent(_ url: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > 5 { paths = Array(paths.prefix(5)) }
        UserDefaults.standard.set(paths, forKey: recentKey)
        recentFolders = paths.compactMap { URL(fileURLWithPath: $0) }
    }

    private func loadRecentFolders() {
        let paths = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
        recentFolders = paths.compactMap { URL(fileURLWithPath: $0) }
    }
}

// MARK: - Folder Picker (UIDocumentPickerViewController wrapper)

struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Documents File Browser View

struct DocumentsBrowserView: View {
    @ObservedObject var folderManager: FolderManager
    let theme: ParadiseTheme
    @State private var files: [URL] = []
    @State private var showShareSheet = false
    @State private var shareURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("EXPORTS & FILES")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(theme.mutedColor)
                    .tracking(1.5)
                Spacer()
                Button {
                    files = folderManager.listDocuments()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(theme.mutedColor)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Divider().background(theme.surfaceBorder)

            if files.isEmpty {
                VStack(spacing: 6) {
                    Text("No exports yet")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(theme.mutedColor)
                    Text("Files you export will\nappear here and in\nthe Files app")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.mutedColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(files, id: \.path) { file in
                            DocumentFileRow(url: file, theme: theme) {
                                shareURL = file
                                showShareSheet = true
                            }
                        }
                    }.padding(8)
                }
            }
        }
        .onAppear { files = folderManager.listDocuments() }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(url: url)
            }
        }
    }
}

struct DocumentFileRow: View {
    let url: URL
    let theme: ParadiseTheme
    let onShare: () -> Void

    var size: String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1_048_576 { return "\(bytes/1024) KB" }
        return String(format: "%.1f MB", Double(bytes)/1_048_576)
    }

    var icon: String {
        switch url.pathExtension.lowercased() {
        case "ipa":   return "📱"
        case "zip":   return "📦"
        case "py":    return "🐍"
        case "swift": return "🔷"
        case "json":  return "📋"
        case "yaml", "yml": return "⚙️"
        default:      return "📄"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                Text(size)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(theme.mutedColor)
            }
            Spacer()
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
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
