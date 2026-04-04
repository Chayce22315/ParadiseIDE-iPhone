import SwiftUI

struct SnippetsView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var t: ParadiseTheme { vm.theme }

    var filteredSnippets: [CodeSnippet] {
        if searchText.isEmpty { return vm.snippets }
        let query = searchText.lowercased()
        return vm.snippets.filter {
            $0.name.lowercased().contains(query) ||
            $0.language.lowercased().contains(query) ||
            $0.description.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Code Snippets")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(t.accent)
                            Text("Ready-to-use templates for quick starts")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(t.mutedColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(t.mutedColor)
                                .font(.system(size: 13))
                            TextField("Search snippets...", text: $searchText)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(t.textColor)
                                .tint(t.accent)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.surfaceBorder, lineWidth: 0.5))
                        )

                        LazyVStack(spacing: 12) {
                            ForEach(filteredSnippets) { snippet in
                                SnippetCard(snippet: snippet, theme: t) {
                                    vm.newTabFromSnippet(snippet)
                                    dismiss()
                                }
                            }
                        }

                        if filteredSnippets.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(t.mutedColor.opacity(0.4))
                                Text("No snippets found")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(t.mutedColor)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

struct SnippetCard: View {
    let snippet: CodeSnippet
    let theme: ParadiseTheme
    let onUse: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(theme.accent.opacity(0.12)).frame(width: 38, height: 38)
                        Image(systemName: snippet.icon).font(.system(size: 15)).foregroundColor(theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snippet.name)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(theme.textColor)
                        HStack(spacing: 6) {
                            Text(snippet.language.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.accent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(theme.accent.opacity(0.12)))
                            Text(snippet.description)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(theme.mutedColor)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.mutedColor)
                }
            }
            .buttonStyle(.plain)
            .padding(14)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(snippet.code)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(theme.textColor)
                            .padding(12)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                    )

                    Button(action: onUse) {
                        HStack {
                            Image(systemName: "doc.badge.plus").font(.system(size: 12))
                            Text("Use Snippet")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.accent.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.accent.opacity(0.3), lineWidth: 0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.surfaceBorder, lineWidth: 0.5))
        )
    }
}
