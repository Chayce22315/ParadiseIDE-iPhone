import SwiftUI
import ActivityKit

// MARK: - Paradise Live Activity Attributes

struct ParadiseCodingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var fileName: String
        var language: String
        var lineCount: Int
        var sessionDuration: String
        var productivityScore: Int
        var productivityEmoji: String
        var filesEdited: Int
        var aiSuggestions: Int
        var petEmoji: String
        var themeName: String
    }

    var sessionId: String
}

// MARK: - Dynamic Island Presenter

@MainActor
final class DynamicIslandPresenter: ObservableObject {

    static let shared = DynamicIslandPresenter()

    @Published var isActive = false
    private var currentActivity: Activity<ParadiseCodingAttributes>?

    func startSession(vm: EditorViewModel) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            vm.isLiveActivityRunning = true
            vm.startLiveActivity()
            return
        }

        let attributes = ParadiseCodingAttributes(sessionId: UUID().uuidString)
        let state = buildState(from: vm)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActive = true
            vm.isLiveActivityRunning = true
            vm.startLiveActivity()
        } catch {
            vm.isLiveActivityRunning = true
            vm.startLiveActivity()
        }
    }

    func updateSession(vm: EditorViewModel) {
        guard let activity = currentActivity else { return }
        let state = buildState(from: vm)
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func endSession(vm: EditorViewModel) {
        if let activity = currentActivity {
            let state = buildState(from: vm)
            Task {
                await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
        isActive = false
        vm.stopLiveActivity()
    }

    private func buildState(from vm: EditorViewModel) -> ParadiseCodingAttributes.ContentState {
        .init(
            fileName: vm.activeTab?.name ?? "No file",
            language: vm.activeTab?.language.uppercased() ?? "SWIFT",
            lineCount: vm.lineCount,
            sessionDuration: vm.sessionStats.formattedDuration,
            productivityScore: vm.sessionStats.productivityScore,
            productivityEmoji: vm.sessionStats.productivityEmoji,
            filesEdited: vm.sessionStats.filesEdited.count,
            aiSuggestions: vm.sessionStats.aiSuggestionsReceived,
            petEmoji: vm.theme.petEmoji,
            themeName: vm.theme.name
        )
    }
}

// MARK: - Dynamic Island Control View (in-app panel that mirrors what the DI shows)

struct DynamicIslandControlView: View {
    @EnvironmentObject var vm: EditorViewModel
    @ObservedObject var presenter = DynamicIslandPresenter.shared
    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "island")
                        .font(.system(size: 14))
                        .foregroundColor(t.accent)
                    Text("Dynamic Island")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(t.textColor)
                }
                Spacer()
                Button {
                    if vm.isLiveActivityRunning {
                        presenter.endSession(vm: vm)
                    } else {
                        presenter.startSession(vm: vm)
                    }
                } label: {
                    Text(vm.isLiveActivityRunning ? "Stop" : "Start")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(vm.isLiveActivityRunning ? .red : t.accent)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(vm.isLiveActivityRunning ? Color.red.opacity(0.12) : t.accent.opacity(0.12))
                                .overlay(Capsule().stroke(vm.isLiveActivityRunning ? Color.red.opacity(0.4) : t.accent.opacity(0.4), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
            }

            if vm.isLiveActivityRunning {
                // Live Activity Preview
                VStack(spacing: 12) {
                    // Compact leading + trailing preview
                    HStack {
                        HStack(spacing: 6) {
                            Text(t.petEmoji).font(.system(size: 16))
                            Text(vm.activeTab?.name ?? "Paradise")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(t.textColor)
                                .lineLimit(1)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text(vm.sessionStats.productivityEmoji)
                            Text("\(vm.sessionStats.productivityScore)%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(t.accent)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )

                    // Expanded preview
                    VStack(spacing: 10) {
                        Text("EXPANDED VIEW")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(t.mutedColor)
                            .tracking(1)

                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t.petEmoji).font(.system(size: 28))
                                Text("Paradise IDE")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(vm.sessionStats.formattedDuration)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            VStack(alignment: .trailing, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(vm.activeTab?.name ?? "--")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }

                                HStack(spacing: 14) {
                                    IslandStat(icon: "text.alignleft", value: "\(vm.lineCount)", color: .cyan)
                                    IslandStat(icon: "keyboard", value: "\(vm.sessionStats.totalKeystrokes)", color: .green)
                                    IslandStat(icon: "sparkles", value: "\(vm.sessionStats.aiSuggestionsReceived)", color: .purple)
                                }

                                HStack(spacing: 6) {
                                    Text(vm.sessionStats.productivityEmoji)
                                    ProgressView(value: Double(vm.sessionStats.productivityScore), total: 100)
                                        .tint(productivityColor)
                                        .frame(width: 60)
                                    Text("\(vm.sessionStats.productivityScore)%")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(productivityColor)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(Array(vm.sessionStats.filesEdited.prefix(4)), id: \.self) { file in
                                Text(file)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Color.white.opacity(0.1)))
                            }
                            if vm.sessionStats.filesEdited.count > 4 {
                                Text("+\(vm.sessionStats.filesEdited.count - 4)")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(t.mutedColor)
                    Text("Start a live session to see coding stats on your Dynamic Island")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(t.mutedColor)
                        .lineSpacing(2)
                }
                .padding(12)
            }
        }
    }

    var productivityColor: Color {
        switch vm.sessionStats.productivityScore {
        case 80...100: return .red
        case 60..<80:  return .orange
        case 40..<60:  return .yellow
        case 20..<40:  return .green
        default:       return .cyan
        }
    }
}

struct IslandStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Live Activity Widget definition
// Note: The actual Widget extension target is needed for real Dynamic Island rendering.
// This provides the SwiftUI views that would be used in the widget bundle.

struct ParadiseLiveActivityView: View {
    let state: ParadiseCodingAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(state.petEmoji)
                    Text(state.fileName)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Text("\(state.lineCount) lines  \(state.sessionDuration)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(state.productivityEmoji) \(state.productivityScore)%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("\(state.filesEdited) files")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
    }
}
