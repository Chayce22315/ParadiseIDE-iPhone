import Foundation

// MARK: - AIService
// All AI calls go to the Paradise server, which proxies to Anthropic.
// The API key never touches the device.

@MainActor
final class AIService: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var lastResponse: String = ""
    @Published var isConfigured: Bool = false

    var serverHost: String = "localhost"
    var serverPort: String = "8765"

    private var baseURL: String {
        "http://\(serverHost):\(serverPort)"
    }

    // MARK: - Check server AI status

    func checkStatus() async {
        guard let url = URL(string: "\(baseURL)/ai/status") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let configured = json["configured"] as? Bool {
                isConfigured = configured
            }
        } catch {
            isConfigured = false
        }
    }

    // MARK: - Complete / ask anything

    func complete(prompt: String, context: String = "") async -> String {
        return await post(endpoint: "/ai/complete", prompt: prompt, context: context)
    }

    // MARK: - Explain an error

    func explainError(_ error: String, code: String = "") async -> String {
        return await post(endpoint: "/ai/explain-error", prompt: error, context: code)
    }

    // MARK: - Fix code

    func fixCode(_ code: String, problem: String = "") async -> String {
        return await post(endpoint: "/ai/fix", prompt: problem, context: code)
    }

    // MARK: - Explain code

    func explainCode(_ code: String) async -> String {
        return await post(endpoint: "/ai/explain-code", prompt: "", context: code)
    }

    // MARK: - Private POST helper

    private func post(endpoint: String, prompt: String, context: String, maxTokens: Int = 512) async -> String {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return "Invalid server URL."
        }

        isLoading = true
        defer { Task { @MainActor in self.isLoading = false } }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body: [String: Any] = [
            "prompt": prompt,
            "context": context,
            "max_tokens": maxTokens
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            if let http = response as? HTTPURLResponse, http.statusCode == 503 {
                return "AI not configured on server. Set ANTHROPIC_API_KEY in .env"
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = json["result"] as? String {
                lastResponse = result
                return result
            }

            return "Could not parse AI response."
        } catch {
            return "Server error: \(error.localizedDescription)"
        }
    }
}
