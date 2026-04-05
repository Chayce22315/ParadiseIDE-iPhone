import SwiftUI
import WidgetKit
import ActivityKit

struct ParadiseIDELiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParadiseIDEAttributes.self) { context in
            // Lock screen / notification banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("Paradise IDE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Text(context.state.fileName.isEmpty ? "Paradise IDE" : context.state.fileName)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(max(context.state.lineCount, 1)) lines")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text(context.state.language.isEmpty ? "SWIFT" : context.state.language.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .activityBackgroundTint(.black.opacity(0.9))
            .activitySystemActionForegroundColor(.cyan)

        } dynamicIsland: { context in
            DynamicIsland {
                // ======== EXPANDED VIEW ========

                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("PARADISE")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.7))
                                .tracking(1.5)
                        }

                        HStack(spacing: 5) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text(displayName(context.state.fileName))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(displayLang(context.state.language))
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.cyan))

                        // Status indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor(for: context.state.status))
                                .frame(width: 6, height: 6)
                            Text(context.state.status)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(statusColor(for: context.state.status))
                        }
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {}

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Stats row
                        HStack(spacing: 0) {
                            makeStatBox(
                                icon: "text.line.last.and.arrowtriangle.forward",
                                value: "\(context.state.lineCount)",
                                label: "LINES",
                                color: .cyan
                            )
                            makeDivider()
                            makeStatBox(
                                icon: "square.on.square",
                                value: "\(context.state.tabCount)",
                                label: "TABS",
                                color: .green
                            )
                            makeDivider()
                            makeStatBox(
                                icon: "cpu",
                                value: context.state.aiActive ? "ON" : "OFF",
                                label: "AI",
                                color: context.state.aiActive ? .purple : .gray
                            )
                            makeDivider()
                            makeStatBox(
                                icon: statusIcon(for: context.state.status),
                                value: String(context.state.status.prefix(5)),
                                label: "MODE",
                                color: statusColor(for: context.state.status)
                            )
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.06))
                        )

                        // Last action text
                        if !context.state.lastAction.isEmpty {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.cyan.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                Text(context.state.lastAction)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(displayName(context.state.fileName).prefix(8))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

            } compactTrailing: {
                Text("\(max(context.state.lineCount, 1))L")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

            } minimal: {
                // ======== MINIMAL ========
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
            }
        }
    }

    // MARK: - Helpers

    func makeDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 0.5, height: 28)
    }

    func makeStatBox(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    func displayName(_ name: String) -> String {
        name.isEmpty ? "Paradise IDE" : name
    }

    func displayLang(_ lang: String) -> String {
        let l = lang.trimmingCharacters(in: .whitespaces)
        return l.isEmpty ? "SWIFT" : l.uppercased()
    }

    func statusIcon(for status: String) -> String {
        switch status.lowercased() {
        case "coding":     return "keyboard.fill"
        case "background": return "moon.fill"
        case "paused":     return "pause.circle.fill"
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
