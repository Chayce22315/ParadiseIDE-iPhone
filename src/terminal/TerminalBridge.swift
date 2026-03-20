import SwiftUI
import Combine

// MARK: - ConnectionState

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected:   return "Disconnected"
        case .connecting:     return "Connecting..."
        case .connected:      return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - WorkspaceFile

struct WorkspaceFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int

    var icon: String {
        switch (name as NSString).pathExtension.lowercased() {
        case "py":            return "py"
        case "swift":         return "sw"
        case "js", "ts":      return "js"
        case "json":          return "json"
        case "zip":           return "zip"
        case "txt", "md":     return "txt"
        case "sh":            return "sh"
        case "ipa":           return "ipa"
        case "apk":           return "apk"
        default:              return "file"
        }
    }

    var sizeLabel: String {
        if size < 1024      { return "\(size) B" }
        if size < 1_048_576 { return "\(size / 1024) KB" }
        return String(format: "%.1f MB", Double(size) / 1_048_576)
    }
}

// MARK: - TerminalBridge

@MainActor
final class TerminalBridge: NSObject, ObservableObject, URLSessionWebSocketDelegate {

    @Published var state: ConnectionState = .disconnected
    @Published var workspaceFiles: [WorkspaceFile] = []
    @Published var buffer = TerminalBuffer()

    var host: String = "localhost"
    var port: String = "8765"
    let sessionID: String = UUID().uuidString

    private var task: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()

    // MARK: - Connect / Disconnect

    func connect() {
        guard case .disconnected = state else { return }
        guard let url = URL(string: "ws://\(host):\(port)/terminal/\(sessionID)") else {
            buffer.appendSystem("Invalid server URL: ws://\(host):\(port)")
            return
        }
        state = .connecting
        buffer.appendSystem("Connecting to \(url)...")
        task = urlSession.webSocketTask(with: url)
        task?.resume()
        receiveLoop()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
        buffer.appendSystem("Session ended.")
    }

    // MARK: - Send

    func send(command: String) {
        guard case .connected = state else {
            buffer.appendSystem("Not connected.")
            return
        }
        guard
            let data = try? JSONSerialization.data(withJSONObject: ["command": command]),
            let str  = String(data: data, encoding: .utf8)
        else { return }

        task?.send(.string(str)) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.buffer.append("Send error: \(error.localizedDescription)", kind: .error)
                }
            }
        }
    }

    // MARK: - Receive loop

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Task { @MainActor in
                    self.state = .error(error.localizedDescription)
                    self.buffer.append("Connection lost: \(error.localizedDescription)", kind: .error)
                }
            case .success(let msg):
                if case .string(let json) = msg {
                    Task { @MainActor in self.route(json) }
                }
                Task { @MainActor in self.receiveLoop() }
            }
        }
    }

    // MARK: - Route messages

    private func route(_ raw: String) {
        guard
            let data    = raw.data(using: .utf8),
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let typeStr = json["type"] as? String,
            let payload = json["data"] as? String
        else { return }

        switch typeStr {
        case "banner":
            state = .connected
            buffer.appendBanner(payload)

        case "stdout":
            buffer.append(payload, kind: .output)

        case "stderr":
            buffer.append(payload, kind: .error)

        case "prompt":
            buffer.isRunning = false

        case "clear":
            buffer.clear()

        case "exit_code":
            if let code = json["code"] as? Int, code != 0 {
                buffer.append("Exited with code \(code)", kind: .system)
            }
            buffer.isRunning = false

        case "download_complete":
            let name = (json["filename"] as? String) ?? payload
            let size = json["size"] as? Int ?? 0
            buffer.append("Downloaded: \(name) (\(formatBytes(size)))", kind: .info)
            Task { await refreshFiles() }

        case "file_list":
            if let files = json["files"] as? [[String: Any]] {
                workspaceFiles = files.compactMap { d in
                    guard
                        let name = d["name"] as? String,
                        let size = d["size"] as? Int
                    else { return nil }
                    return WorkspaceFile(name: name, path: (d["path"] as? String) ?? name, size: size)
                }
            }

        case "info":
            buffer.append(payload, kind: .info)

        default:
            buffer.append(payload, kind: .output)
        }
    }

    // MARK: - URLSessionWebSocketDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { @MainActor in self.state = .connected }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { @MainActor in
            self.state = .disconnected
            self.buffer.appendSystem("Connection closed.")
        }
    }

    // MARK: - REST helpers

    func writeFile(name: String, content: String) async {
        guard let url = URL(string: "http://\(host):\(port)/files/write") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "session_id": sessionID,
            "filename":   name,
            "content":    content
        ])
        do {
            let (_, res) = try await URLSession.shared.data(for: req)
            if (res as? HTTPURLResponse)?.statusCode == 200 {
                buffer.append("Sent '\(name)' to server workspace.", kind: .info)
                await refreshFiles()
            }
        } catch {
            buffer.append("Upload error: \(error.localizedDescription)", kind: .error)
        }
    }

    func refreshFiles() async {
        send(command: "files")
    }

    func downloadURL(for filename: String) -> URL? {
        URL(string: "http://\(host):\(port)/files/download/\(sessionID)/\(filename)")
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024       { return "\(n) B" }
        if n < 1_048_576  { return "\(n / 1024) KB" }
        return String(format: "%.1f MB", Double(n) / 1_048_576)
    }
}
