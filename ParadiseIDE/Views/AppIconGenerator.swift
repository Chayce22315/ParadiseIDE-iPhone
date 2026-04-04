import SwiftUI
import UIKit

struct AppIconPreview: View {
    var body: some View {
        AppIconDesign()
            .frame(width: 1024, height: 1024)
    }
}

struct AppIconDesign: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.09, blue: 0.20),
                    Color(red: 0.05, green: 0.18, blue: 0.35),
                    Color(red: 0.04, green: 0.30, blue: 0.52),
                    Color(red: 0.12, green: 0.38, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.45
                        )
                    )
                    .frame(width: w * 0.8, height: w * 0.8)
                    .position(x: w * 0.5, y: h * 0.45)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.6, blue: 0.8).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.3
                        )
                    )
                    .frame(width: w * 0.5, height: w * 0.5)
                    .position(x: w * 0.3, y: h * 0.7)
            }

            VStack(spacing: 0) {
                Text("🌴")
                    .font(.system(size: 280))
                    .shadow(color: Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.4), radius: 30)

                Text("P")
                    .font(.system(size: 200, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.95, blue: 1.0),
                                Color(red: 0.0, green: 0.70, blue: 0.90)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.6), radius: 20)
                    .offset(y: -30)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("IDE")
                        .font(.system(size: 60, weight: .light, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.5))
                        .padding(.trailing, 60)
                        .padding(.bottom, 50)
                }
            }

            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 220, style: .continuous))
    }
}

enum AppIconExporter {
    @MainActor
    static func generateIcon() -> UIImage? {
        let renderer = ImageRenderer(content: AppIconDesign().frame(width: 1024, height: 1024))
        renderer.scale = 1.0
        return renderer.uiImage
    }

    @MainActor
    static func saveIconToDocuments() -> URL? {
        guard let image = generateIcon(),
              let data = image.pngData() else { return nil }

        let url = FolderManager.paradiseDocumentsURL.appendingPathComponent("AppIcon-1024x1024.png")
        try? data.write(to: url)
        return url
    }
}
