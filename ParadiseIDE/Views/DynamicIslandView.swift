import SwiftUI
import ActivityKit

// MARK: - Paradise IDE Live Activity Attributes

@available(iOS 16.2, *)
struct ParadiseIDEAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var fileName: String
        var lineCount: Int
        var language: String
        var status: String
        var buildProgress: Double
        var aiActive: Bool
        var themeName: String
        var tabCount: Int
        var lastAction: String
    }

    var projectName: String
}

// MARK: - Dynamic Island Manager

@MainActor
final class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()

    @Published var isLiveActivityRunning = false

    func startLiveActivity(projectName: String) {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ParadiseIDEAttributes(projectName: projectName)
        let state = ParadiseIDEAttributes.ContentState(
            fileName: "", lineCount: 0, language: "", status: "Ready",
            buildProgress: 0, aiActive: false, themeName: "", tabCount: 0, lastAction: "Idle"
        )

        do {
            let _ = try Activity<ParadiseIDEAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            isLiveActivityRunning = true
        } catch {
            print("Paradise: Failed to start live activity: \(error)")
        }
    }

    func stopLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        Task {
            for activity in Activity<ParadiseIDEAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            isLiveActivityRunning = false
        }
    }
}

// MARK: - In-App Dynamic Island Simulation

struct DynamicIslandBannerView: View {
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var folderManager: FolderManager
    @EnvironmentObject var github: GitHubService
    @ObservedObject var islandManager = DynamicIslandManager.shared
    @State private var expanded = false
    @State private var pulseAnimation = false

    var t: ParadiseTheme { vm.theme }

    var statusIcon: String {
        switch vm.petMood {
        case .typing: return "keyboard"
        case .ai:     return "cpu"
        case .error:  return "exclamationmark.triangle"
        case .happy:  return "checkmark.circle"
        case .idle:   return "circle.fill"
        }
    }

    var statusColor: Color {
        switch vm.petMood {
        case .typing: return t.accent
        case .ai:     return .purple
        case .error:  return .red
        case .happy:  return .green
        case .idle:   return t.mutedColor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if expanded {
                expandedIsland
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
                    ))
            } else {
                compactIsland
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                expanded.toggle()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private var compactIsland: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(statusColor)
                .shadow(color: statusColor.opacity(0.6), radius: pulseAnimation ? 4 : 0)

            if folderManager.rootURL != nil {
                Image(systemName: "folder.fill")
                    .font(.system(size: 8))
                    .foregroundColor(t.accent.opacity(0.6))
                Text(folderManager.rootName)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                Text("·")
                    .foregroundColor(.white.opacity(0.3))
            }

            if let tab = vm.activeTab {
                Text(tab.name)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            } else {
                Text("Paradise IDE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }

            if github.isSignedIn, let user = github.user {
                Text("@\(user.login)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }

            Text("\(vm.lineCount)L")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(t.accent.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private var expandedIsland: some View {
        VStack(spacing: 10) {
            // Top row: file info + language badge
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                        Text(vm.activeTab?.name ?? "Paradise IDE")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Text(statusText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(vm.activeTab?.language.uppercased() ?? "—")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(t.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(t.accent.opacity(0.2)))

                    Text(vm.theme.petEmoji)
                        .font(.system(size: 16))
                }
            }

            // GitHub user row
            if github.isSignedIn, let user = github.user {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                    Text("@\(user.login)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if github.commitStats.todayCommits > 0 {
                        Text("\(github.commitStats.todayCommits) today")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                .padding(.horizontal, 4)
            }

            // Folder info row
            if folderManager.rootURL != nil {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9))
                        .foregroundColor(t.accent.opacity(0.7))
                    Text(folderManager.rootName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer()
                    Text("\(folderManager.totalFileCount) files")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 4)
            }

            // Stats row
            HStack(spacing: 12) {
                IslandStatPill(icon: "doc.text", value: "\(vm.lineCount)", label: "lines", color: t.accent)
                IslandStatPill(icon: "character.cursor.ibeam", value: "\(vm.code.count)", label: "chars", color: t.accent2)
                IslandStatPill(icon: "square.on.square", value: "\(vm.tabs.count)", label: "tabs", color: .green)
                IslandStatPill(icon: "doc.on.doc", value: "\(folderManager.totalFileCount)", label: "files", color: .cyan)
                if github.isSignedIn && github.commitStats.totalCommits > 0 {
                    IslandStatPill(icon: "arrow.triangle.branch", value: "\(github.commitStats.totalCommits)", label: "commits", color: .orange)
                } else {
                    IslandStatPill(icon: "arrow.triangle.branch", value: "\(folderManager.commitCount)", label: "saves", color: .orange)
                }
                if vm.showAIPanel {
                    IslandStatPill(icon: "cpu", value: "ON", label: "AI", color: .purple)
                }
            }

            // Typing progress
            if vm.petMood == .typing {
                ProgressView(value: Double(vm.lineCount % 50) / 50.0)
                    .tint(t.accent)
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [statusColor.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: statusColor.opacity(0.15), radius: 20)
    }

    private var statusText: String {
        switch vm.petMood {
        case .typing: return "Editing in progress..."
        case .ai:     return "AI is analyzing your code"
        case .error:  return "Issue detected in code"
        case .happy:  return "Looking good!"
        case .idle:   return "Ready to code"
        }
    }
}

struct IslandStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(color)

            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
