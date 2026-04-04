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
    @EnvironmentObject var github: GitHubService
    @StateObject private var aiService = AIService()
    @Environment(\.dismiss) private var dismiss
    @State private var tokenInput = ""
    @State private var showTokenEntry = false
    @State private var aiKeyInput = ""
    @State private var showAIKeyEntry = false
    @State private var showCreateRepo = false
    @State private var newRepoName = ""
    @State private var newRepoDesc = ""
    @State private var newRepoPrivate = false
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: AI
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI ENGINE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            VStack(spacing: 10) {
                                HStack(spacing: 10) {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 18))
                                        .foregroundColor(aiService.isConfigured ? .green : t.mutedColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(aiService.isConfigured ? "Groq AI Connected" : "AI Not Configured")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(t.textColor)
                                        Text(aiService.isConfigured ? "Using llama-3.3-70b" : "Add your free Groq API key")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(t.mutedColor)
                                    }
                                    Spacer()
                                    if aiService.isConfigured {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }

                                Button {
                                    showAIKeyEntry = true
                                } label: {
                                    Text(aiService.isConfigured ? "Change API Key" : "Add Groq API Key")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(t.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .liquidGlass(cornerRadius: 10, tint: t.accent, intensity: 1, borderOpacity: 0.2)
                                }
                                .buttonStyle(.plain)

                                Text("Get a free key at console.groq.com\nNo server needed — AI runs from your phone")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(t.mutedColor.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(12)
                            .liquidGlassCard(theme: t, cornerRadius: 14)
                        }
                        .alert("Groq API Key", isPresented: $showAIKeyEntry) {
                            TextField("gsk_xxxxxxxxxxxx", text: $aiKeyInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            Button("Save") {
                                let key = aiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !key.isEmpty else { return }
                                aiService.apiKey = key
                                aiKeyInput = ""
                            }
                            Button("Cancel", role: .cancel) { aiKeyInput = "" }
                        } message: {
                            Text("Enter your Groq API key. Get one free at console.groq.com")
                        }

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

                        // MARK: GitHub
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GITHUB")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(t.mutedColor)
                                .tracking(1.5)

                            if github.isSignedIn {
                                VStack(spacing: 12) {
                                    if let user = github.user {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: user.avatarURL)) { image in
                                                image.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Circle().fill(t.accent.opacity(0.2))
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(t.accent.opacity(0.3), lineWidth: 1))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(user.name ?? user.login)
                                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(t.textColor)
                                                Text("@\(user.login)")
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(t.mutedColor)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(user.publicRepos)")
                                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                    .foregroundColor(t.accent)
                                                Text("repos")
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(t.mutedColor)
                                            }
                                        }
                                        .padding(12)
                                        .liquidGlassCard(theme: t, cornerRadius: 12)
                                    }

                                    if github.commitStats.totalCommits > 0 {
                                        HStack(spacing: 16) {
                                            GitStatBadge(value: "\(github.commitStats.totalCommits)", label: "commits", icon: "arrow.triangle.branch", color: t.accent, theme: t)
                                            GitStatBadge(value: "\(github.commitStats.todayCommits)", label: "today", icon: "sun.max.fill", color: .orange, theme: t)
                                            GitStatBadge(value: "\(github.commitStats.weekCommits)", label: "this week", icon: "calendar", color: .green, theme: t)
                                        }
                                    }

                                    if !github.repos.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("SELECT REPO")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(t.mutedColor)
                                                .tracking(1)

                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(github.repos.prefix(10)) { repo in
                                                        Button {
                                                            github.selectRepo(repo)
                                                        } label: {
                                                            VStack(alignment: .leading, spacing: 3) {
                                                                Text(repo.name)
                                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                                    .foregroundColor(github.selectedRepo?.id == repo.id ? t.accent : t.textColor)
                                                                    .lineLimit(1)
                                                                HStack(spacing: 4) {
                                                                    if let lang = repo.language {
                                                                        Text(lang)
                                                                            .font(.system(size: 8, design: .monospaced))
                                                                            .foregroundColor(t.mutedColor)
                                                                    }
                                                                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                                                    Text("\(repo.stargazersCount)")
                                                                        .font(.system(size: 8, design: .monospaced))
                                                                        .foregroundColor(t.mutedColor)
                                                                }
                                                            }
                                                            .padding(.horizontal, 10).padding(.vertical, 8)
                                                            .liquidGlass(
                                                                cornerRadius: 8,
                                                                tint: github.selectedRepo?.id == repo.id ? t.accent : .white,
                                                                intensity: github.selectedRepo?.id == repo.id ? 2 : 0.5,
                                                                borderOpacity: github.selectedRepo?.id == repo.id ? 0.3 : 0.1
                                                            )
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    HStack(spacing: 10) {
                                        Button {
                                            showCreateRepo = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                Text("New Repo")
                                            }
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(t.accent)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .liquidGlass(cornerRadius: 10, tint: t.accent, intensity: 1, borderOpacity: 0.2)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            github.signOut()
                                        } label: {
                                            HStack {
                                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                                Text("Sign Out")
                                            }
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.red.opacity(0.8))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .liquidGlass(cornerRadius: 10, tint: .red, intensity: 0.5, borderOpacity: 0.15)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "arrow.triangle.branch")
                                            .font(.system(size: 28))
                                            .foregroundColor(t.mutedColor)
                                        Text("Connect GitHub to see your commits")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(t.mutedColor)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(16)

                                    Button {
                                        showTokenEntry = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "key.fill")
                                            Text("Sign in with Personal Access Token")
                                        }
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule().fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        )
                                        .overlay(Capsule().stroke(t.accent.opacity(0.3), lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)

                                    Text("Generate a token at github.com/settings/tokens\nwith 'repo' scope")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(t.mutedColor.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(12)
                                .liquidGlassCard(theme: t, cornerRadius: 14)
                            }
                        }
                        .alert("GitHub Token", isPresented: $showTokenEntry) {
                            TextField("ghp_xxxxxxxxxxxx", text: $tokenInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            Button("Sign In") {
                                let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !token.isEmpty else { return }
                                Task { await github.signInWithToken(token) }
                                tokenInput = ""
                            }
                            Button("Cancel", role: .cancel) { tokenInput = "" }
                        } message: {
                            Text("Enter a GitHub Personal Access Token with 'repo' scope. Generate one at github.com/settings/tokens")
                        }
                        .alert("Create Repository", isPresented: $showCreateRepo) {
                            TextField("repo-name", text: $newRepoName)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            TextField("Description (optional)", text: $newRepoDesc)
                            Button("Create") {
                                let name = newRepoName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !name.isEmpty else { return }
                                Task {
                                    let _ = await github.createRepo(
                                        name: name,
                                        description: newRepoDesc,
                                        isPrivate: false
                                    )
                                }
                                newRepoName = ""
                                newRepoDesc = ""
                            }
                            Button("Cancel", role: .cancel) {
                                newRepoName = ""
                                newRepoDesc = ""
                            }
                        } message: {
                            Text("Create a new public GitHub repository")
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

// MARK: - Git Stat Badge

struct GitStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let theme: ParadiseTheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textColor)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(theme.mutedColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .liquidGlassCard(theme: theme, cornerRadius: 10)
    }
}
