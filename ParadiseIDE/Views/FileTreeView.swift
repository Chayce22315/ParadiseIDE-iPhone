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
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXPLORER")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                        .tracking(1.5)
                    Text(folderManager.rootName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.accent)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        newItemParent = folderManager.rootURL
                        showNewFile = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 13))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        newItemParent = folderManager.rootURL
                        showNewFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 13))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        folderManager.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        folderManager.showPicker = true
                    } label: {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 13))
                            .foregroundColor(t.accent)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Rectangle()
                .fill(t.surfaceBorder.opacity(0.3))
                .frame(height: 0.5)

            if folderManager.rootNode == nil {
                VStack(spacing: 14) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundColor(t.mutedColor.opacity(0.3))
                    Text("No folder open")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Button("Open Folder") {
                        folderManager.showPicker = true
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(t.accent.opacity(0.12))
                            .overlay(Capsule().stroke(t.accent.opacity(0.5), lineWidth: 0.5))
                    )
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let root = folderManager.rootNode {
                ScrollView(showsIndicators: false) {
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
                    .padding(.vertical, 6)
                }
            }
        }
        .background(
            t.surface.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().fill(t.surfaceBorder.opacity(0.3)).frame(width: 0.5), alignment: .trailing)
        .fullScreenCover(isPresented: $folderManager.showPicker) {
            FolderPicker(
                onPick: { url in
                    folderManager.showPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        folderManager.openFolder(url)
                    }
                },
                onCancel: { folderManager.showPicker = false }
            )
            .ignoresSafeArea()
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
            HStack(spacing: 5) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: CGFloat(depth * 16))

                if node.isDirectory {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                        .frame(width: 14)
                } else {
                    Rectangle().fill(Color.clear).frame(width: 14)
                }

                Image(systemName: node.icon)
                    .font(.system(size: 12))
                    .foregroundColor(node.isDirectory ? theme.accent.opacity(0.7) : theme.mutedColor)
                    .frame(width: 18)

                Text(node.name)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(isActive ? theme.accent : theme.textColor)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? theme.accent.opacity(0.10) : Color.clear)
                    .padding(.horizontal, 4)
            )
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
