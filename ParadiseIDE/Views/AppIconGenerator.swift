import SwiftUI
import UIKit

struct AppIconPreview: View {
    var size: CGFloat = 256

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.03, green: 0.06, blue: 0.14), location: 0),
                            .init(color: Color(red: 0.04, green: 0.12, blue: 0.28), location: 0.3),
                            .init(color: Color(red: 0.05, green: 0.20, blue: 0.40), location: 0.6),
                            .init(color: Color(red: 0.12, green: 0.30, blue: 0.42), location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Subtle grid pattern
            VStack(spacing: size * 0.06) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: size * 0.06) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.02))
                                .frame(width: size * 0.08, height: size * 0.03)
                        }
                    }
                }
            }
            .rotationEffect(.degrees(-8))

            // Glow orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0, green: 0.83, blue: 1).opacity(0.25),
                            Color(red: 0, green: 0.83, blue: 1).opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
                .offset(x: size * 0.05, y: size * 0.05)

            // Palm tree silhouette (simplified)
            PalmTreeShape()
                .fill(Color(red: 0, green: 0.83, blue: 1).opacity(0.08))
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(x: -size * 0.2, y: size * 0.15)

            // Code brackets
            VStack(spacing: size * 0.02) {
                HStack(spacing: size * 0.04) {
                    Text("{")
                        .font(.system(size: size * 0.28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 0.83, blue: 1))

                    Text("}")
                        .font(.system(size: size * 0.28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 0.83, blue: 1))
                }

                // "Paradise" text
                Text("PARADISE")
                    .font(.system(size: size * 0.065, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0, green: 0.83, blue: 1).opacity(0.9))
                    .tracking(size * 0.02)
            }
            .offset(y: -size * 0.02)

            // Top-left sparkle
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.07))
                .foregroundColor(Color(red: 0, green: 0.83, blue: 1).opacity(0.6))
                .offset(x: -size * 0.28, y: -size * 0.28)

            // Bottom-right wave
            Image(systemName: "water.waves")
                .font(.system(size: size * 0.09))
                .foregroundColor(Color(red: 0, green: 0.83, blue: 1).opacity(0.3))
                .offset(x: size * 0.28, y: size * 0.3)

            // Glass highlight
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)
        }
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

struct PalmTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Trunk
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.95))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.35),
            control: CGPoint(x: w * 0.42, y: h * 0.65)
        )
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.95),
            control: CGPoint(x: w * 0.55, y: h * 0.65)
        )
        path.closeSubpath()

        // Leaf 1 (right)
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.25),
            control: CGPoint(x: w * 0.7, y: h * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.48, y: h * 0.38),
            control: CGPoint(x: w * 0.7, y: h * 0.35)
        )

        // Leaf 2 (left)
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.33))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.05, y: h * 0.20),
            control: CGPoint(x: w * 0.25, y: h * 0.10)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.48, y: h * 0.37),
            control: CGPoint(x: w * 0.25, y: h * 0.35)
        )

        // Leaf 3 (up-right)
        path.move(to: CGPoint(x: w * 0.49, y: h * 0.32))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.05),
            control: CGPoint(x: w * 0.62, y: h * 0.05)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.35),
            control: CGPoint(x: w * 0.62, y: h * 0.18)
        )

        return path
    }
}

// MARK: - Icon Renderer

enum AppIconRenderer {

    @MainActor
    static func renderIcon(size: CGFloat) -> UIImage? {
        let view = AppIconPreview(size: size)
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    @MainActor
    static func saveIcon() -> URL? {
        guard let image = renderIcon(size: 1024),
              let data = image.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParadiseIDE-Icon-1024.png")
        try? data.write(to: url)
        return url
    }
}
