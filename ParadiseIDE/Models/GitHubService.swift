import SwiftUI
import AuthenticationServices

// MARK: - GitHub User

struct GitHubUser: Codable {
    let login: String
    let id: Int
    let avatarURL: String
    let name: String?
    let bio: String?
    let publicRepos: Int
    let followers: Int
    let following: Int

    enum CodingKeys: String, CodingKey {
        case login, id, name, bio, followers, following
        case avatarURL = "avatar_url"
        case publicRepos = "public_repos"
    }
}

// MARK: - GitHub Repo

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let isPrivate: Bool
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case isPrivate = "private"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case updatedAt = "updated_at"
    }
}

// MARK: - GitHub Commit Stats

struct GitHubCommitStats {
    var totalCommits: Int = 0
    var todayCommits: Int = 0
    var weekCommits: Int = 0
    var repoName: String = ""
}

// MARK: - GitHub Service

@MainActor
final class GitHubService: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var user: GitHubUser?
    @Published var repos: [GitHubRepo] = []
    @Published var commitStats = GitHubCommitStats()
    @Published var selectedRepo: GitHubRepo?
    @Published var errorMessage: String?

    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "paradise.github.token") }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "paradise.github.token")
            } else {
                UserDefaults.standard.removeObject(forKey: "paradise.github.token")
            }
        }
    }

    private var savedRepoName: String? {
        get { UserDefaults.standard.string(forKey: "paradise.github.repo") }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "paradise.github.repo")
            } else {
                UserDefaults.standard.removeObject(forKey: "paradise.github.repo")
            }
        }
    }

    init() {
        if accessToken != nil {
            isSignedIn = true
            Task { await loadProfile() }
        }
    }

    // MARK: - Device Flow Sign In

    func signInWithToken(_ token: String) async {
        accessToken = token
        isSignedIn = true
        await loadProfile()
    }

    func signOut() {
        accessToken = nil
        isSignedIn = false
        user = nil
        repos = []
        commitStats = GitHubCommitStats()
        selectedRepo = nil
        savedRepoName = nil
    }

    // MARK: - Load Profile

    func loadProfile() async {
        guard let token = accessToken else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await githubGet("/user", token: token)
            repos = try await githubGet("/user/repos?sort=updated&per_page=30", token: token)

            if let repoName = savedRepoName,
               let repo = repos.first(where: { $0.fullName == repoName }) {
                selectedRepo = repo
                await fetchCommitStats(for: repo)
            } else if let first = repos.first {
                selectRepo(first)
            }
        } catch {
            errorMessage = "Failed to load GitHub profile: \(error.localizedDescription)"
        }
    }

    // MARK: - Select Repo

    func selectRepo(_ repo: GitHubRepo) {
        selectedRepo = repo
        savedRepoName = repo.fullName
        Task { await fetchCommitStats(for: repo) }
    }

    // MARK: - Fetch Commits

    func fetchCommitStats(for repo: GitHubRepo) async {
        guard let token = accessToken, let username = user?.login else { return }

        do {
            let commits: [[String: Any]] = try await githubGetRaw(
                "/repos/\(repo.fullName)/commits?author=\(username)&per_page=100",
                token: token
            )

            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let isoFallback = ISO8601DateFormatter()
            isoFallback.formatOptions = [.withInternetDateTime]

            var todayCount = 0
            var weekCount = 0

            for commit in commits {
                if let commitObj = commit["commit"] as? [String: Any],
                   let author = commitObj["author"] as? [String: Any],
                   let dateStr = author["date"] as? String {
                    let date = iso.date(from: dateStr) ?? isoFallback.date(from: dateStr)
                    if let date = date {
                        if date >= startOfToday { todayCount += 1 }
                        if date >= startOfWeek { weekCount += 1 }
                    }
                }
            }

            commitStats = GitHubCommitStats(
                totalCommits: commits.count,
                todayCommits: todayCount,
                weekCommits: weekCount,
                repoName: repo.name
            )
        } catch {
            errorMessage = "Failed to fetch commits: \(error.localizedDescription)"
        }
    }

    func refreshCommits() async {
        if let repo = selectedRepo {
            await fetchCommitStats(for: repo)
        }
    }

    // MARK: - API Helpers

    private func githubGet<T: Decodable>(_ path: String, token: String) async throws -> T {
        guard let url = URL(string: "https://api.github.com\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            signOut()
            throw URLError(.userAuthenticationRequired)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func githubGetRaw(_ path: String, token: String) async throws -> [[String: Any]] {
        guard let url = URL(string: "https://api.github.com\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            signOut()
            throw URLError(.userAuthenticationRequired)
        }

        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }
}
