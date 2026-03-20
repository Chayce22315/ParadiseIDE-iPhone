import SwiftUI

struct RightPanelView: View {
@EnvironmentObject var vm: EditorViewModel
@EnvironmentObject var folderManager: FolderManager
var t: ParadiseTheme { vm.theme }

```
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 18) {

            // Current folder
            PanelSection(title: "PROJECT FOLDER") {
                VStack(alignment: .leading, spacing: 6) {
                    if let url = folderManager.currentFolderURL {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(t.accent)
                                .font(.system(size: 12))
                            Text(url.lastPathComponent)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(t.accent)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(t.accent.opacity(0.10))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))

                        Button("Clear folder") { folderManager.clearFolder() }
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    } else {
                        Text("No folder selected\nTap the folder button\nin the top bar")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                            .lineSpacing(4)
                    }
                }
            }

            // Exports / Documents browser
            PanelSection(title: "EXPORTS & FILES") {
                DocumentsBrowserView(folderManager: folderManager, theme: t)
                    .frame(minHeight: 120)
            }

            // AI Co-pilot
            PanelSection(title: "AI CO-PILOT") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Active & watching")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.textColor)
                    ForEach(["Auto-complete", "Error explain", "Fix suggest",
                             "Guide mode \(vm.guideMode ? "ON" : "OFF")"], id: \.self) { item in
                        Text(item)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
            }

            // Build targets
            PanelSection(title: "BUILD TARGETS") {
                VStack(spacing: 4) {
                    ForEach(["Windows", "macOS", "Android", "iOS"], id: \.self) { p in
                        Text(p)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(t.textColor)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.surfaceBorder, lineWidth: 1))
                    }
                }
            }

            // Edition
            PanelSection(title: "EDITION") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.edition.badge) \(vm.edition.rawValue)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(t.accent)
                    Text(vm.edition.price)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(t.accent.opacity(0.10))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.surfaceBorder, lineWidth: 1))
            }

            // Session stats
            PanelSection(title: "SESSION") {
                VStack(alignment: .leading, spacing: 4) {
                    StatRow(label: "Lines", value: "\(vm.lineCount)", theme: vm.theme)
                    StatRow(label: "Chars", value: "\(vm.code.count)", theme: vm.theme)
                    StatRow(label: "Theme", value: t.name, theme: vm.theme)
                    StatRow(label: "Perf",  value: vm.performanceMode ? "ON" : "OFF", theme: vm.theme)
                }
            }
        }
        .padding(14)
    }
    .background(t.surface)
    .overlay(Rectangle().frame(width: 1).foregroundColor(t.surfaceBorder), alignment: .leading)
}
```

}

}

// MARK: - Helper views

struct PanelSection<Content: View>: View {
@EnvironmentObject var vm: EditorViewModel
let title: String
@ViewBuilder let content: () -> Content

```
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(vm.theme.mutedColor)
            .tracking(1.5)
        content()
    }
}
```

}

struct StatRow: View {
let label: String
let value: String
let theme: ParadiseTheme

```
var body: some View {
    HStack {
        Text(label + ":")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(theme.mutedColor)
        Spacer()
        Text(value)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(theme.accent)
    }
}
```

}