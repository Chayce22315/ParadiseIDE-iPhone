import SwiftUI

// MARK: - Liquid Glass Effect Modifiers

struct LiquidGlassBackground: ViewModifier {
    let cornerRadius: CGFloat
    let tintColor: Color
    let intensity: Double
    let borderOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(intensity * 0.15),
                                    tintColor.opacity(intensity * 0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                tintColor.opacity(borderOpacity * 0.5),
                                Color.white.opacity(borderOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

struct LiquidGlassCard: ViewModifier {
    let theme: ParadiseTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.accent.opacity(0.06))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                theme.accent.opacity(0.15),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            )
            .shadow(color: theme.accent.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct LiquidGlassToolbar: ViewModifier {
    let theme: ParadiseTheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accent.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.06),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
    }
}

struct GlassPill: ViewModifier {
    let color: Color
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(isActive ? color.opacity(0.18) : Color.white.opacity(0.05))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(
                        isActive ? color.opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 0.6
                    )
            )
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        tint: Color = .white,
        intensity: Double = 1.0,
        borderOpacity: Double = 0.15
    ) -> some View {
        modifier(LiquidGlassBackground(
            cornerRadius: cornerRadius,
            tintColor: tint,
            intensity: intensity,
            borderOpacity: borderOpacity
        ))
    }

    func liquidGlassCard(theme: ParadiseTheme, cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassCard(theme: theme, cornerRadius: cornerRadius))
    }

    func liquidGlassToolbar(theme: ParadiseTheme) -> some View {
        modifier(LiquidGlassToolbar(theme: theme))
    }

    func glassPill(color: Color, isActive: Bool = false) -> some View {
        modifier(GlassPill(color: color, isActive: isActive))
    }
}
