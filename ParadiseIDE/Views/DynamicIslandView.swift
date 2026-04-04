import SwiftUI

// MARK: - Dynamic Island Banner (in-app simulation for devices/contexts without ActivityKit)

struct DynamicIslandBanner: View {
    @EnvironmentObject var vm: EditorViewModel
    @ObservedObject var liveActivity = LiveActivityManager.shared
    @State private var expanded = false

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        VStack(spacing: 0) {
            if expanded {
                expandedView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            } else {
                compactView
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: expanded ? 28 : 22, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: expanded ? 28 : 22, style: .continuous)
                .fill(.black)
                .shadow(color: t.accent.opacity(0.3), radius: expanded ? 20 : 8)
        )
        .padding(.horizontal, expanded ? 16 : 60)
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                expanded.toggle()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: liveActivity.codingSeconds)
    }

    // MARK: - Compact View

    private var compactView: some View {
        HStack(spacing: 10) {
            Text(t.petEmoji)
                .font(.system(size: 18))

            Spacer()

            if let tab = vm.activeTab {
                Text(tab.name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text("Paradise IDE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(vm.activeTab?.isDirty == true ? Color.orange : t.accent)
                    .frame(width: 6, height: 6)
                Text(timerText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(t.petEmoji)
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Paradise IDE")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundColor(t.accent)

                    if let tab = vm.activeTab {
                        Text(tab.name)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(t.accent)
                        Text(timerText)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(t.accent)
                    }

                    if vm.activeTab?.isDirty == true {
                        Text("UNSAVED")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
            }

            HStack(spacing: 16) {
                islandStat(icon: "text.alignleft", label: "Lines", value: "\(vm.lineCount)")
                islandStat(icon: "character.cursor.ibeam", label: "Chars", value: "\(vm.code.count)")
                islandStat(icon: "doc.on.doc", label: "Tabs", value: "\(vm.tabs.count)")

                if let tab = vm.activeTab {
                    islandStat(icon: "chevron.left.forwardslash.chevron.right", label: "Lang", value: tab.language.prefix(6).uppercased())
                }
            }

            HStack(spacing: 12) {
                Text(t.name)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(t.accent.opacity(0.7))

                Spacer()

                Text(vm.petMood.message.isEmpty ? "Coding..." : vm.petMood.message)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Circle()
                    .fill(t.accent)
                    .frame(width: 6, height: 6)
                    .shadow(color: t.accent, radius: 4)
            }
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func islandStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(t.accent.opacity(0.8))
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var timerText: String {
        let s = liveActivity.codingSeconds
        let m = s / 60
        let sec = s % 60
        if m > 0 { return String(format: "%d:%02d", m, sec) }
        return "\(sec)s"
    }
}
