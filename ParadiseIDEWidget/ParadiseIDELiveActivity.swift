import SwiftUI
import WidgetKit
import ActivityKit

struct ParadiseIDELiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParadiseIDEAttributes.self) { context in
            // Lock screen banner
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .bold))
                VStack(alignment: .leading) {
                    Text("Paradise IDE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(context.state.fileName) • \(context.state.lineCount) lines")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(context.state.status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding()
            .activityBackgroundTint(.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.fileName.isEmpty ? "Paradise" : context.state.fileName)
                            .font(.caption)
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.cyan)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.lineCount)L")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(context.state.language.isEmpty ? "Swift" : context.state.language,
                              systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.caption2)
                            .foregroundColor(.cyan)
                        Spacer()
                        Label(context.state.status.isEmpty ? "Ready" : context.state.status,
                              systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                        Label("\(context.state.tabCount) tabs",
                              systemImage: "square.on.square")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 4)
                }
                DynamicIslandExpandedRegion(.center) {}
            } compactLeading: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundColor(.cyan)
            } compactTrailing: {
                Text("\(context.state.lineCount)L")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            } minimal: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(.cyan)
            }
        }
    }
}
