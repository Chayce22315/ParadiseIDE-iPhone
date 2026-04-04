import SwiftUI

// MARK: - Paradise IDE App Icon

struct ParadiseAppIcon: View {
    let size: CGFloat

    init(size: CGFloat = 1024) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.06, blue: 0.16),
                            Color(red: 0.05, green: 0.14, blue: 0.30),
                            Color(red: 0.04, green: 0.24, blue: 0.42),
                            Color(red: 0.08, green: 0.32, blue: 0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Subtle radial glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)
                .offset(y: -size * 0.05)

            // Code bracket decorations (left)
            Text("{")
                .font(.system(size: size * 0.28, weight: .ultraLight, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.15))
                .offset(x: -size * 0.22, y: -size * 0.08)

            // Code bracket decorations (right)
            Text("}")
                .font(.system(size: size * 0.28, weight: .ultraLight, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.15))
                .offset(x: size * 0.22, y: size * 0.12)

            // Palm tree
            Text("🌴")
                .font(.system(size: size * 0.32))
                .offset(y: -size * 0.12)

            // Chevron brackets < />
            HStack(spacing: size * 0.02) {
                Text("<")
                    .font(.system(size: size * 0.14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0))

                Text("/>")
                    .font(.system(size: size * 0.14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0))
            }
            .offset(y: size * 0.18)

            // Bottom text
            Text("PARADISE")
                .font(.system(size: size * 0.065, weight: .medium, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.7))
                .tracking(size * 0.015)
                .offset(y: size * 0.34)

            // Corner accent dots
            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.4))
                .frame(width: size * 0.025, height: size * 0.025)
                .offset(x: -size * 0.34, y: -size * 0.34)

            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.3))
                .frame(width: size * 0.018, height: size * 0.018)
                .offset(x: size * 0.34, y: -size * 0.34)

            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.2))
                .frame(width: size * 0.015, height: size * 0.015)
                .offset(x: size * 0.34, y: size * 0.34)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Icon Preview Sheet

struct AppIconPreviewSheet: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    var t: ParadiseTheme { vm.theme }

    let iconSizes: [(String, CGFloat)] = [
        ("App Store (1024pt)", 200),
        ("iPhone @3x (180pt)", 120),
        ("iPhone @2x (120pt)", 80),
        ("Spotlight (80pt)", 60),
        ("Settings (58pt)", 40),
        ("Notification (40pt)", 30),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Paradise IDE Icon")
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(t.accent)

                        Text("Generated app icon at all required sizes")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(t.mutedColor)

                        ParadiseAppIcon(size: 220)
                            .shadow(color: t.accent.opacity(0.4), radius: 30)
                            .padding(.vertical, 8)

                        ForEach(iconSizes, id: \.0) { label, displaySize in
                            HStack(spacing: 16) {
                                ParadiseAppIcon(size: displaySize)
                                    .shadow(color: .black.opacity(0.3), radius: 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(label)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(t.textColor)

                                    Text("\(Int(displaySize))x\(Int(displaySize))pt display")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 14, tint: t.accent, intensity: 0.4)
                        }
                    }
                    .padding(20)
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
