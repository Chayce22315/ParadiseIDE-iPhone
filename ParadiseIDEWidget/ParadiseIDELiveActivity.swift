import SwiftUI
import WidgetKit
import ActivityKit

struct ParadiseIDELiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParadiseIDEAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(context.state.fileName, systemImage: "doc.fill")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                        Text(context.state.status)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.language.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.cyan.opacity(0.2)))
                        Text("\(context.state.tabCount) tabs")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        StatLabel(value: "\(context.state.lineCount)", label: "lines", color: .cyan)
                        if context.state.aiActive {
                            StatLabel(value: "ON", label: "AI", color: .purple)
                        }
                        StatLabel(value: context.state.status, label: "status", color: .green)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: statusIcon(for: context.state.status))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor(for: context.state.status))
            } compactTrailing: {
                Text("\(context.state.lineCount)L")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
            } minimal: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
            }
        }
    }

    func statusIcon(for status: String) -> String {
        switch status.lowercased() {
        case "coding":     return "keyboard"
        case "background": return "moon.fill"
        case "paused":     return "pause.circle"
        default:           return "circle.fill"
        }
    }

    func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "coding":     return .cyan
        case "background": return .orange
        case "paused":     return .yellow
        default:           return .gray
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<ParadiseIDEAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Paradise IDE")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Text(context.state.fileName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(context.state.lineCount) lines")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
                Text(context.state.status)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
    }
}

struct StatLabel: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
