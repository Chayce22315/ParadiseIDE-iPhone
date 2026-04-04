import SwiftUI
import UIKit

struct AppIconDesign: View {
    let size: CGFloat

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

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)

            VStack(spacing: -size * 0.04) {
                Text("🌴")
                    .font(.system(size: size * 0.28))

                Text("P")
                    .font(.system(size: size * 0.22, weight: .bold, design: .serif))
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
                    .shadow(color: Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.5), radius: size * 0.02)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("IDE")
                        .font(.system(size: size * 0.06, weight: .light, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.4))
                        .padding(.trailing, size * 0.06)
                        .padding(.bottom, size * 0.05)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

enum AppIconExporter {
    @MainActor
    static func generateIcon(size: CGFloat = 1024) -> UIImage? {
        let renderer = ImageRenderer(content: AppIconDesign(size: size))
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

    @MainActor
    static func generateIfNeeded() {
        let url = FolderManager.paradiseDocumentsURL.appendingPathComponent("AppIcon-1024x1024.png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let _ = saveIconToDocuments()
            print("Paradise: App icon generated at \(url.path)")
        }
    }
}
