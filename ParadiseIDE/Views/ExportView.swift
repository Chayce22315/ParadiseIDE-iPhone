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
  - echo "Build complete! 🌴"
"""
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚙️ Paradise Export")
                                .font(.system(size: 22, weight: .medium, design: .serif))
                                .italic()
                                .foregroundColor(t.accent)
                            Text("Cross-platform build via YAML workflow")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }

                        // Config fields
                        VStack(alignment: .leading, spacing: 12) {
                            ExportField(label: "App Name", value: $appName, theme: t)
                            ExportField(label: "Version",  value: $appVersion, theme: t)
                        }

                        // Platform selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLATFORMS")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(allPlatforms, id: \.self) { platform in
                                    let key = platform.components(separatedBy: " ").last ?? platform
                                    let selected = selectedPlatforms.contains(key)

                                    Button {
                                        if selected { selectedPlatforms.remove(key) }
                                        else { selectedPlatforms.insert(key) }
                                    } label: {
                                        Text(platform)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(selected ? t.accent : t.mutedColor)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selected ? t.accent.opacity(0.15) : Color.black.opacity(0.2))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(selected ? t.accent : t.surfaceBorder, lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // iOS options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("iOS OPTIONS")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            Toggle(isOn: $unsigned) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unsigned IPA")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                    Text("Default when no certificate provided")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            .tint(t.accent)
                        }

                        // YAML preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GENERATED YAML")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(yaml)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.textColor)
                                    .lineSpacing(4)
                                    .padding(14)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.surfaceBorder, lineWidth: 1))
                        }

                        // Execute button
                        Button {
                            withAnimation(.spring(response: 0.3)) { buildPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                buildPressed = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text(buildPressed ? "🚀 Building..." : "🚀 EXECUTE PARADISE BUILD")
                                    .font(.system(size: 13, design: .monospaced))
                                    .tracking(0.5)
                            }
                            .foregroundColor(t.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(t.accent.opacity(0.18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(t.accent, lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(buildPressed ? 0.97 : 1.0)
                        .shadow(color: t.accent.opacity(buildPressed ? 0.5 : 0.2), radius: buildPressed ? 20 : 8)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 13, design: .monospaced))
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
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(theme.mutedColor)
                .tracking(1.5)

            TextField(label, text: $value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(theme.textColor)
                .padding(10)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.surfaceBorder, lineWidth: 1))
                .tint(theme.accent)
        }
    }
}
