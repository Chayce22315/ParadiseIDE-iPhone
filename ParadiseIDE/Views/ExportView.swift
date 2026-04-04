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
                    VStack(alignment: .leading, spacing: 22) {

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Paradise Export")
                                .font(.system(size: 24, weight: .semibold, design: .serif))
                                .italic()
                                .foregroundColor(t.accent)
                            Text("Cross-platform build via YAML workflow")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            ExportField(label: "App Name", value: $appName, theme: t)
                            ExportField(label: "Version",  value: $appVersion, theme: t)
                        }
                        .padding(14)
                        .liquidGlassCard(theme: t)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("PLATFORMS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                                            .liquidGlass(
                                                cornerRadius: 10,
                                                tint: selected ? t.accent : .white,
                                                intensity: selected ? 2 : 0.5,
                                                borderOpacity: selected ? 0.3 : 0.1
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("iOS OPTIONS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            Toggle(isOn: $unsigned) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Unsigned IPA")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                    Text("Default when no certificate provided")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            .tint(t.accent)
                            .padding(12)
                            .liquidGlassCard(theme: t, cornerRadius: 12)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("GENERATED YAML")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                            .liquidGlassCard(theme: t, cornerRadius: 12)
                        }

                        Button {
                            withAnimation(.spring(response: 0.3)) { buildPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                buildPressed = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "hammer.fill")
                                Text(buildPressed ? "Building..." : "EXECUTE BUILD")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(t.accent.opacity(0.3))
                                    .background(.ultraThinMaterial, in: Capsule())
                            )
                            .overlay(
                                Capsule().stroke(t.accent.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(buildPressed ? 0.97 : 1.0)
                        .shadow(color: t.accent.opacity(buildPressed ? 0.5 : 0.2), radius: buildPressed ? 24 : 10)
                    }
                    .padding(22)
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
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(theme.mutedColor)
                .tracking(1.5)

            TextField(label, text: $value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(theme.textColor)
                .padding(12)
                .background(Color.black.opacity(0.2))
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.surfaceBorder, lineWidth: 0.5))
                .tint(theme.accent)
        }
    }
}
