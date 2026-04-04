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
                    Text(context.state.fileName)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(context.state.lineCount) lines")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text(context.state.language.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .activityBackgroundTint(.black.opacity(0.9))
            .activitySystemActionForegroundColor(.cyan)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.fileName)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(context.state.status)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.language.uppercased())
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.cyan))
                        Text("\(context.state.lineCount)L")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 0) {
                        makeStatBox(icon: "doc.text.fill", value: "\(context.state.lineCount)", label: "LINES")
                        makeStatBox(icon: "square.on.square.fill", value: "\(context.state.tabCount)", label: "TABS")
                        if context.state.aiActive {
                            makeStatBox(icon: "cpu.fill", value: "ON", label: "AI")
                        }
                        makeStatBox(icon: "circle.fill", value: context.state.status, label: "STATUS")
                    }
                    .padding(.top, 6)
                }

                DynamicIslandExpandedRegion(.center) {}

            } compactLeading: {
                // Compact left side
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(context.state.fileName.prefix(8))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

            } compactTrailing: {
                // Compact right side
                Text("\(context.state.lineCount)L")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

            } minimal: {
                // Minimal (when another app also has a Live Activity)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
            }
        }
    }

    func makeStatBox(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.cyan)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
