import SwiftUI
import WebKit

struct HTMLPreviewView: View {
    let html: String
    let fileName: String
    let theme: ParadiseTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                WebViewRepresentable(html: html)
            }
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openInDefaultBrowser()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                            Text("Open in Safari")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    private func openInDefaultBrowser() {
        let previewDir = FolderManager.paradiseDocumentsURL
        let fileURL = previewDir.appendingPathComponent(fileName.isEmpty ? "preview.html" : fileName)
        try? html.write(to: fileURL, atomically: true, encoding: .utf8)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        let controller = UIDocumentInteractionController(url: fileURL)
        controller.uti = "public.html"
        if !controller.presentOpenInMenu(from: .zero, in: root.view, animated: true) {
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            root.present(activityVC, animated: true)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
