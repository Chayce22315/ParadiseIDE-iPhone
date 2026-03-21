import SwiftUI

// MARK: - FileTreeView (real filesystem)

struct FileTreeView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    var t: ParadiseTheme { vm.theme }

    @State private var showNewFile = false
    @State private var showNewFolder = false
    @State private var newItemName = ""
    @State private var newItemParent: URL? = nil
    @State private var showRenameSheet = false
    @State private var renameTarget: FileNode? = nil
    @State private var renameTo = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(folderManager.rootName.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .tracking(1.5)
                    .lineLimit(1)

                Spacer()

                // New file
                Button {
                    newItemParent = folderManager.rootURL
                    showNewFile = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(t.mutedColor)
                }.buttonStyle(.plain)

                // New folder
                Button {
                    newItemParent = folderManager.rootURL
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(t.mutedColor)
                }.buttonStyle(.plain)

                // Refresh
                Button {
                    folderManager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(t.mutedColor)
                }.buttonStyle(.plain)

                // Open folder
                Button {
                    folderManager.showPicker = true
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundColor(t.accent)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider().background(t.surfaceBorder)

            if folderManager.rootNode == nil {
                // No folder open
                VStack(spacing: 10) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(t.mutedColor.opacity(0.5))
                    Text("No folder open")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Button("Open Folder") {
                        folderManager.showPicker = true
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(t.accent, lineWidth: 1))
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let root = folderManager.rootNode {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let children = root.children {
                            ForEach(children) { node in
                                FileNodeRow(
                                    node: node,
                                    depth: 0,
                                    theme: t,
                                    onNewFile: { parent in
                                        newItemParent = parent
                                        showNewFile = true
                                    },
                                    onNewFolder: { parent in
                                        newItemParent = parent
                                        showNewFolder = true
                                    },
                                    onRename: { node in
                                        renameTarget = node
                                        renameTo = node.name
                                        showRenameSheet = true
                                    },
                                    onDelete: { node in
                                        try? folderManager.deleteItem(node.url)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(t.surface)
        .overlay(Rectangle().frame(width: 1).foregroundColor(t.surfaceBorder), alignment: .trailing)
        .sheet(isPresented: $folderManager.showPicker) {
            FolderPicker { url in
                folderManager.openFolder(url)
                folderManager.showPicker = false
            }
        }
        .alert("New File", isPresented: $showNewFile) {
            TextField("filename.swift", text: $newItemName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Create") {
                if let parent = newItemParent, !newItemName.isEmpty {
                    if let url = try? folderManager.createFile(in: parent, name: newItemName) {
                        openFile(url: url, language: FileNode(url: url).language)
                    }
                    newItemName = ""
                }
            }
            Button("Cancel", role: .cancel) { newItemName = "" }
        }
        .alert("New Folder", isPresented: $showNewFolder) {
            TextField("folder-name", text: $newItemName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Create") {
                if let parent = newItemParent, !newItemName.isEmpty {
                    try? folderManager.createFolder(in: parent, name: newItemName)
                    newItemName = ""
                }
            }
            Button("Cancel", role: .cancel) { newItemName = "" }
        }
        .alert("Rename", isPresented: $showRenameSheet) {
            TextField("new name", text: $renameTo)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Rename") {
                if let node = renameTarget, !renameTo.isEmpty {
                    try? folderManager.renameItem(node.url, to: renameTo)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func openFile(url: URL, language: String) {
        if let content = folderManager.readFile(url) {
            vm.openFile(url: url, content: content, language: language)
        }
    }
}

// MARK: - File Node Row

struct FileNodeRow: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @ObservedObject var node: FileNode
    let depth: Int
    let theme: ParadiseTheme
    let onNewFile: (URL) -> Void
    let onNewFolder: (URL) -> Void
    let onRename: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    var isActive: Bool {
        vm.activeTab?.url == node.url
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                // Indent
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: CGFloat(depth * 14))

                // Expand arrow for dirs
                if node.isDirectory {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                        .frame(width: 12)
                } else {
                    Rectangle().fill(Color.clear).frame(width: 12)
                }

                // Icon
                Image(systemName: node.icon)
                    .font(.system(size: 11))
                    .foregroundColor(node.isDirectory ? theme.accent.opacity(0.8) : theme.mutedColor)
                    .frame(width: 16)

                // Name
                Text(node.name)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isActive ? theme.accent : theme.textColor)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(isActive ? theme.accent.opacity(0.12) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        node.isExpanded.toggle()
                        if node.isExpanded {
                            folderManager.loadChildren(of: node)
                        }
                    }
                } else {
                    if let content = folderManager.readFile(node.url) {
                        vm.openFile(url: node.url, content: content, language: node.language)
                    }
                }
            }
            .contextMenu {
                if node.isDirectory {
                    Button {
                        onNewFile(node.url)
                    } label: { Label("New File", systemImage: "doc.badge.plus") }

                    Button {
                        onNewFolder(node.url)
                    } label: { Label("New Folder", systemImage: "folder.badge.plus") }
                }

                Button {
                    onRename(node)
                } label: { Label("Rename", systemImage: "pencil") }

                Button(role: .destructive) {
                    onDelete(node)
                } label: { Label("Delete", systemImage: "trash") }
            }

            // Children
            if node.isDirectory && node.isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileNodeRow(
                        node: child,
                        depth: depth + 1,
                        theme: theme,
                        onNewFile: onNewFile,
                        onNewFolder: onNewFolder,
                        onRename: onRename,
                        onDelete: onDelete
                    )
                }
            }
        }
    }
}
