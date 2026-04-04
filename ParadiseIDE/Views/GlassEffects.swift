import SwiftUI

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tintColor: Color
    let intensity: Double
    let borderOpacity: Double

    init(
        cornerRadius: CGFloat = 16,
        tintColor: Color = .white,
        intensity: Double = 0.6,
        borderOpacity: Double = 0.25
    ) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.intensity = intensity
        self.borderOpacity = borderOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tintColor.opacity(0.04 * intensity))

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(0.12 * intensity),
                                    tintColor.opacity(0.02 * intensity),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                tintColor.opacity(borderOpacity),
                                tintColor.opacity(borderOpacity * 0.3),
                                tintColor.opacity(borderOpacity * 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = 16,
        tint: Color = .white,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.content = content
    }

    var body: some View {
        content()
            .modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tintColor: tint))
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    let tint: Color
    let cornerRadius: CGFloat

    init(tint: Color = .white, cornerRadius: CGFloat = 10) {
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(configuration.isPressed ? 0.2 : 0.08))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.3),
                                tint.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        tint: Color = .white,
        intensity: Double = 0.6,
        borderOpacity: Double = 0.25
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            tintColor: tint,
            intensity: intensity,
            borderOpacity: borderOpacity
        ))
    }

    func glassButton(tint: Color = .white, cornerRadius: CGFloat = 10) -> some View {
        buttonStyle(GlassButtonStyle(tint: tint, cornerRadius: cornerRadius))
    }
}

// MARK: - Frosted Divider

struct FrostedDivider: View {
    let color: Color

    init(_ color: Color = .white) {
        self.color = color
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.0),
                        color.opacity(0.15),
                        color.opacity(0.15),
                        color.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

// MARK: - Animated Gradient Orb (for glass depth)

struct GlassOrb: View {
    let color: Color
    let size: CGFloat
    @State private var phase: CGFloat = 0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.3), color.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: size / 4)
            .offset(x: sin(phase) * 10, y: cos(phase) * 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    phase = .pi * 2
                }
            }
    }
}
