import Foundation

// MARK: - AIService
// Calls Groq API directly from the device. No server needed.
// Singleton so the API key persists across all views.

@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isLoading: Bool = false
    @Published var isConfigured: Bool = false

    private let groqURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.3-70b-versatile"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "paradise.groq.apikey") ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: "paradise.groq.apikey")
            UserDefaults.standard.synchronize()
            isConfigured = !newValue.isEmpty
        }
    }

    init() {
        refreshConfigured()
    }

    func refreshConfigured() {
        let key = UserDefaults.standard.string(forKey: "paradise.groq.apikey") ?? ""
        isConfigured = !key.isEmpty
    }

    func complete(prompt: String, context: String = "", maxTokens: Int = 1024) async -> String {
        refreshConfigured()
        let systemMsg = "You are a helpful coding assistant inside Paradise IDE, a mobile code editor. Be concise and practical."
        var userMsg = prompt
        if !context.isEmpty {
            userMsg += "\n\nCode:\n```\n\(context.prefix(3000))\n```"
        }
        return await chat(system: systemMsg, user: userMsg, maxTokens: maxTokens)
    }

    func explainError(_ error: String, code: String = "") async -> String {
        refreshConfigured()
        let system = "You are a coding assistant. Explain this error simply and suggest a fix. Be concise."
        var user = "Error: \(error)"
        if !code.isEmpty { user += "\n\nCode:\n```\n\(code.prefix(2000))\n```" }
        return await chat(system: system, user: user, maxTokens: 400)
    }

    func fixCode(_ code: String, problem: String = "") async -> String {
        refreshConfigured()
        let system = "You are a coding assistant. Fix the bugs in this code. Return the corrected code with brief explanation."
        var user = "Fix this code:"
        if !problem.isEmpty { user += "\nProblem: \(problem)" }
        user += "\n\n```\n\(code.prefix(3000))\n```"
        return await chat(system: system, user: user, maxTokens: 800)
    }

    func explainCode(_ code: String) async -> String {
        refreshConfigured()
        let system = "You are a coding assistant. Explain what this code does in simple terms. Be concise."
        let user = "Explain this code:\n\n```\n\(code.prefix(3000))\n```"
        return await chat(system: system, user: user, maxTokens: 400)
    }

    private func chat(system: String, user: String, maxTokens: Int) async -> String {
        guard isConfigured else {
            return "No API key set. Go to Settings and add your Groq API key.\n\nGet one free at: console.groq.com"
        }

        guard let url = URL(string: groqURL) else { return "Invalid API URL." }

        isLoading = true
        defer { isLoading = false }

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.3
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 {
                    return "Invalid API key. Check your Groq API key in Settings."
                }
                if http.statusCode == 429 {
                    return "Rate limited. Wait a moment and try again."
                }
                if http.statusCode != 200 {
                    let errBody = String(data: data, encoding: .utf8) ?? ""
                    return "API error \(http.statusCode): \(errBody.prefix(200))"
                }
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }

            return "Could not parse AI response."
        } catch {
            return "Network error: \(error.localizedDescription)"
        }
    }
}
