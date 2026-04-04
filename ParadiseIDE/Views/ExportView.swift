import SwiftUI

struct ExportView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    var t: ParadiseTheme { vm.theme }

    @State private var selectedPlatforms: Set<String> = ["iOS", "macOS"]
    @State private var appVersion = "1.0.0"
    @State private var appName = "paradise-app"
    @State private var unsigned = true
    @State private var buildPressed = false

    let allPlatforms = ["🪟 Windows", "🍎 macOS", "🤖 Android", "📱 iOS"]

    var yaml: String {
        let plats = selectedPlatforms.sorted().joined(separator: "\n  - ")
        return """
# Paradise IDE Export Workflow
name: \(appName)
version: \(appVersion)

platforms:
  - \(plats.isEmpty ? "ios" : plats.lowercased().components(separatedBy: "\n  - ").joined(separator: "\n  - "))

build:
  sign: \(!unsigned)
  output: ./dist
  ios:
    scheme: ParadiseIDE
    export_method: \(unsigned ? "development" : "app-store")

post-build:
  - zip ./dist/\(appName)-\(appVersion).ipa
  - echo "Build complete!"
"""
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Paradise Export")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .italic()
                                .foregroundColor(t.accent)
                            Text("Cross-platform build via YAML workflow")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }

                        // Config fields
                        VStack(alignment: .leading, spacing: 14) {
                            ExportField(label: "App Name", value: $appName, theme: t)
                            ExportField(label: "Version", value: $appVersion, theme: t)
                        }
                        .glassCard(theme: t, cornerRadius: 14, padding: 14)

                        // Platform selector
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PLATFORMS")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(allPlatforms, id: \.self) { platform in
                                    let key = platform.components(separatedBy: " ").last ?? platform
                                    let selected = selectedPlatforms.contains(key)

                                    Button {
                                        if selected { selectedPlatforms.remove(key) }
                                        else { selectedPlatforms.insert(key) }
                                    } label: {
                                        Text(platform)
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(selected ? t.accent : t.mutedColor)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selected ? t.accent.opacity(0.12) : Color.white.opacity(0.03))
                                                    .background(selected ? .ultraThinMaterial : .bar, in: RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(
                                                                selected ? t.accent.opacity(0.5) : t.surfaceBorder.opacity(0.3),
                                                                lineWidth: 0.5
                                                            )
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // iOS options
                        VStack(alignment: .leading, spacing: 10) {
                            Text("iOS OPTIONS")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            Toggle(isOn: $unsigned) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Unsigned IPA")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                    Text("Default when no certificate provided")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            .tint(t.accent)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(t.surface.opacity(0.5))
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.surfaceBorder.opacity(0.3), lineWidth: 0.5))
                            )
                        }

                        // YAML preview
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GENERATED YAML")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(yaml)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(t.textColor)
                                    .lineSpacing(4)
                                    .padding(16)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.surfaceBorder.opacity(0.3), lineWidth: 0.5))
                            )
                        }

                        // Execute button
                        Button {
                            withAnimation(.spring(response: 0.3)) { buildPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                buildPressed = false
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: buildPressed ? "gear" : "hammer.fill")
                                    .font(.system(size: 14))
                                Text(buildPressed ? "Building..." : "EXECUTE PARADISE BUILD")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .tracking(0.5)
                            }
                            .foregroundColor(t.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(t.accent.opacity(0.15))
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(t.accent.opacity(0.6), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(buildPressed ? 0.97 : 1.0)
                        .shadow(color: t.accent.opacity(buildPressed ? 0.5 : 0.2), radius: buildPressed ? 20 : 8)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

// MARK: - Export field

struct ExportField: View {
    let label: String
    @Binding var value: String
    let theme: ParadiseTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(theme.mutedColor)
                .tracking(1.5)

            TextField(label, text: $value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(theme.textColor)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder.opacity(0.3), lineWidth: 0.5))
                )
                .tint(theme.accent)
        }
    }
}
