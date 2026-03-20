import SwiftUI

struct FileTreeView: View {
    @EnvironmentObject var vm: EditorViewModel

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("EXPLORER")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(t.mutedColor)
                .tracking(1.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            // File list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.fileTree) { item in
                        FileRowView(item: item)
                    }
                }
            }

            Spacer()
        }
        .background(t.surface)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(t.surfaceBorder),
            alignment: .trailing
        )
    }
}

// MARK: - File Row

struct FileRowView: View {
    @EnvironmentObject var vm: EditorViewModel
    let item: FileItem

    var t: ParadiseTheme { vm.theme }
    var isSelected: Bool { vm.selectedFile == item.name && item.type == .file }

    var icon: String {
        switch item.type {
        case .directory: return "📁"
        case .file:
            if item.name.hasSuffix(".yaml") { return "⚙️" }
            if item.name.hasSuffix(".swift") { return "🔷" }
            return "📄"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 11))
            Text(item.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(
                    isSelected ? t.accent
                    : item.type == .directory ? t.textColor
                    : t.mutedColor
                )
                .lineLimit(1)
        }
        .padding(.leading, CGFloat(12 + item.depth * 12))
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? t.accent.opacity(0.12) : Color.clear)
        .overlay(
            Rectangle()
                .frame(width: 2)
                .foregroundColor(isSelected ? t.accent : .clear),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .file {
                vm.selectedFile = item.name
            }
        }
    }
}
