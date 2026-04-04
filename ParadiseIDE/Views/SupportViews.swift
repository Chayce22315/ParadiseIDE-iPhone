import SwiftUI

// MARK: - Status Bar

struct StatusBarView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        HStack(spacing: 14) {
            if let tab = vm.activeTab {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill").font(.system(size: 8)).foregroundColor(t.mutedColor)
                    Text(tab.name).font(.system(size: 10, design: .monospaced)).foregroundColor(t.mutedColor)
                }
                Text(tab.language.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(t.accent.opacity(0.12)))
            }
            Text("Ln \(vm.lineCount)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(t.mutedColor)
            Text("\(vm.wordCount)w")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(t.mutedColor)
            Text(t.petEmoji)
            Spacer()
            Text("Paradise IDE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(t.mutedColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 26)
        .background(t.accent.opacity(0.06))
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(t.surfaceBorder), alignment: .top)
    }
}

// MARK: - Error Toast

struct ErrorToastView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("PARADISE TOOLS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                        .tracking(1)
                    Text("No stress! Looks like a small issue. The AI can help fix it.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(t.textColor)
                }
                Spacer()
                Button {
                    vm.showErrorToast = false
                    vm.petMood = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(t.mutedColor)
                        .font(.system(size: 16))
                }.buttonStyle(.plain)
            }
            .padding(16)
            .liquidGlass(cornerRadius: 18, tint: .orange, intensity: 1.5, borderOpacity: 0.25)
            .shadow(color: .orange.opacity(0.15), radius: 24)
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
    }
}

// MARK: - Particle Layer

struct ParticleLayerView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(t.particles.enumerated()), id: \.offset) { i, emoji in
                Text(emoji)
                    .font(.system(size: CGFloat(20 + (i % 3) * 10)))
                    .position(
                        x: geo.size.width * (0.10 + Double(i) * 0.18 + Double(i % 2) * 0.08),
                        y: geo.size.height * (0.05 + Double(i % 4) * 0.22)
                    )
                    .opacity(0.08 + Double(i % 3) * 0.03)
                    .blur(radius: 1)
                    .modifier(FloatModifier(delay: Double(i) * 0.7, range: 22))
            }
        }
    }
}

struct FloatModifier: ViewModifier {
    let delay: Double
    let range: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content.offset(y: offset).onAppear {
            withAnimation(.easeInOut(duration: 3.5 + delay * 0.4).repeatForever(autoreverses: true).delay(delay)) {
                offset = -range
            }
        }
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APPEARANCE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            ForEach(ParadiseTheme.all) { theme in
                                Button {
                                    withAnimation { vm.theme = theme }
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle().fill(theme.accent).frame(width: 20, height: 20)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.name)
                                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                .foregroundColor(t.textColor)
                                            Text(theme.ambientLabel)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(t.mutedColor)
                                        }
                                        Spacer()
                                        if vm.theme.id == theme.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(theme.accent)
                                        }
                                    }
                                    .padding(12)
                                    .liquidGlassCard(theme: theme, cornerRadius: 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("PERFORMANCE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            Toggle(isOn: $vm.performanceMode) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Performance Mode")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                    Text("Disables animations and particles")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                            }
                            .tint(t.accent)
                            .padding(12)
                            .liquidGlassCard(theme: t, cornerRadius: 12)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("EDITION")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            ForEach(IDEEdition.allCases, id: \.self) { edition in
                                Button {
                                    vm.edition = edition
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(edition.rawValue)
                                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                .foregroundColor(t.textColor)
                                            Text(edition.price)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(t.mutedColor)
                                        }
                                        Spacer()
                                        if vm.edition == edition {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(t.accent)
                                        }
                                    }
                                    .padding(12)
                                    .liquidGlassCard(theme: t, cornerRadius: 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ABOUT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            VStack(spacing: 8) {
                                Text(t.petEmoji).font(.system(size: 36))
                                Text("Paradise IDE")
                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                    .italic()
                                    .foregroundColor(t.accent)
                                Text("v2.0 — Liquid Glass Edition")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(t.mutedColor)
                                Text("Built for iPhone 16 Plus")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(t.mutedColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .liquidGlassCard(theme: t, cornerRadius: 14)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
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

// MARK: - Snippets Library

struct SnippetsLibraryView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    var t: ParadiseTheme { vm.theme }

    let snippets: [(String, String, String)] = [
        ("SwiftUI View", "swift", """
struct MyView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}
"""),
        ("Python Flask", "python", """
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run(debug=True)
"""),
        ("JS Fetch", "javascript", """
async function fetchData(url) {
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error:', error);
    }
}
"""),
        ("HTML Template", "html", """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paradise App</title>
</head>
<body>
    <h1>Hello, Paradise!</h1>
</body>
</html>
"""),
        ("CSS Grid", "css", """
.container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    padding: 1rem;
}

.card {
    background: var(--surface);
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
"""),
        ("Rust Hello", "rust", """
fn main() {
    println!("Hello from Paradise!");
    
    let numbers: Vec<i32> = (1..=10).collect();
    let sum: i32 = numbers.iter().sum();
    println!("Sum of 1..10: {}", sum);
}
"""),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(snippets, id: \.0) { name, lang, code in
                            Button {
                                vm.newUntitledTab(language: lang)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    vm.code = code
                                }
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(name)
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(t.textColor)
                                        Spacer()
                                        Text(lang.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(t.accent)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(t.accent.opacity(0.15)))
                                    }
                                    Text(code.prefix(80) + "...")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                        .lineLimit(2)
                                }
                                .padding(14)
                                .liquidGlassCard(theme: t, cornerRadius: 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Snippets")
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
