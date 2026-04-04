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
    @State private var searchQuery = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(folderManager.rootName.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(t.mutedColor)
                    .tracking(1.2)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        newItemParent = folderManager.rootURL
                        showNewFile = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 11))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        newItemParent = folderManager.rootURL
                        showNewFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 11))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        folderManager.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(t.mutedColor)
                    }.buttonStyle(.plain)

                    Button {
                        folderManager.showPicker = true
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundColor(t.accent)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            FrostedDivider(t.surfaceBorder)

            // Search
            if folderManager.rootNode != nil {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(t.mutedColor.opacity(0.6))

                    TextField("Search files...", text: $searchQuery)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(t.textColor)
                        .tint(t.accent)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.1))

                FrostedDivider(t.surfaceBorder)
            }

            if folderManager.rootNode == nil {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 30))
                        .foregroundColor(t.mutedColor.opacity(0.4))
                    Text("No folder open")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                    Button("Open Folder") {
                        folderManager.showPicker = true
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .liquidGlass(cornerRadius: 8, tint: t.accent, intensity: 0.7)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let root = folderManager.rootNode {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let children = root.children {
                            ForEach(filteredChildren(children)) { node in
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
        .background(.ultraThinMaterial.opacity(0.3))
        .overlay(
            Rectangle().frame(width: 0.5)
                .foregroundColor(t.surfaceBorder),
            alignment: .trailing
        )
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

    private func filteredChildren(_ children: [FileNode]) -> [FileNode] {
        guard !searchQuery.isEmpty else { return children }
        return children.filter { node in
            node.name.localizedCaseInsensitiveContains(searchQuery) ||
            (node.isDirectory && node.children?.contains(where: { $0.name.localizedCaseInsensitiveContains(searchQuery) }) == true)
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
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: CGFloat(depth * 14))

                if node.isDirectory {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                        .frame(width: 12)
                } else {
                    Rectangle().fill(Color.clear).frame(width: 12)
                }

                Image(systemName: node.icon)
                    .font(.system(size: 11))
                    .foregroundColor(node.isDirectory ? theme.accent.opacity(0.8) : theme.mutedColor)
                    .frame(width: 16)

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
