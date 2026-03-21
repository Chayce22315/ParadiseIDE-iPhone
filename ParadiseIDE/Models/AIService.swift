import Foundation

// MARK: - AIService
// All AI calls proxy through the Paradise server which holds the GROQ_API_KEY in .env
// The key never touches the device.

@MainActor
final class AIService: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var isConfigured: Bool = false

    var serverHost: String = "localhost"
    var serverPort: String = "8765"

    private var baseURL: String { "http://\(serverHost):\(serverPort)" }

    func checkStatus() async {
        guard let url = URL(string: "\(baseURL)/ai/status") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let configured = json["configured"] as? Bool {
                isConfigured = configured
            }
        } catch { isConfigured = false }
    }

    func complete(prompt: String, context: String = "", maxTokens: Int = 512) async -> String {
        return await post(endpoint: "/ai/complete", prompt: prompt, context: context, maxTokens: maxTokens)
    }

    func explainError(_ error: String, code: String = "") async -> String {
        return await post(endpoint: "/ai/explain-error", prompt: error, context: code, maxTokens: 300)
    }

    func fixCode(_ code: String, problem: String = "") async -> String {
        return await post(endpoint: "/ai/fix", prompt: problem, context: code, maxTokens: 600)
    }

    func explainCode(_ code: String) async -> String {
        return await post(endpoint: "/ai/explain-code", prompt: "", context: code, maxTokens: 300)
    }

    private func post(endpoint: String, prompt: String, context: String, maxTokens: Int) async -> String {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return "Invalid server URL. Is the server running?"
        }

        isLoading = true
        defer { Task { @MainActor in self.isLoading = false } }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "prompt": prompt,
            "context": context,
            "max_tokens": maxTokens
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 503 {
                    return "AI not configured on server. Add GROQ_API_KEY to src/server/.env"
                }
                if http.statusCode != 200 {
                    return "Server error \(http.statusCode)"
                }
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = json["result"] as? String {
                return result
            }
            return "Could not parse response."
        } catch {
            return "Cannot reach server at \(baseURL). Is it running?"
        }
    }
}
