import Foundation
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Paradise Activity Attributes

struct ParadiseIDEAttributes: Hashable, Codable {
    let projectName: String

    struct ContentState: Codable, Hashable {
        var fileName: String
        var language: String
        var lineCount: Int
        var charCount: Int
        var codingSeconds: Int
        var themeName: String
        var petEmoji: String
        var isDirty: Bool

        var codingTimeFormatted: String {
            let m = codingSeconds / 60
            let s = codingSeconds % 60
            if m > 0 { return "\(m)m \(s)s" }
            return "\(s)s"
        }
    }
}

// MARK: - Live Activity Manager

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var isActivityActive = false
    @Published var codingSeconds: Int = 0

    private var timer: Timer?
    private var activityID: String?

    #if canImport(ActivityKit)
    private var currentActivity: Activity<ParadiseIDEAttributes>?
    #endif

    private init() {}

    func startSession(projectName: String, fileName: String, language: String, lineCount: Int, charCount: Int, themeName: String, petEmoji: String) {
        codingSeconds = 0
        isActivityActive = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.codingSeconds += 1
            }
        }

        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

            let attributes = ParadiseIDEAttributes(projectName: projectName)
            let state = ParadiseIDEAttributes.ContentState(
                fileName: fileName,
                language: language,
                lineCount: lineCount,
                charCount: charCount,
                codingSeconds: 0,
                themeName: themeName,
                petEmoji: petEmoji,
                isDirty: false
            )

            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
                currentActivity = activity
                activityID = activity.id
            } catch {
                print("Paradise: Failed to start Live Activity: \(error)")
            }
        }
        #endif
    }

    func updateActivity(fileName: String, language: String, lineCount: Int, charCount: Int, themeName: String, petEmoji: String, isDirty: Bool) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard let activity = currentActivity else { return }

            let state = ParadiseIDEAttributes.ContentState(
                fileName: fileName,
                language: language,
                lineCount: lineCount,
                charCount: charCount,
                codingSeconds: codingSeconds,
                themeName: themeName,
                petEmoji: petEmoji,
                isDirty: isDirty
            )

            Task {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
        #endif
    }

    func endSession() {
        timer?.invalidate()
        timer = nil
        isActivityActive = false

        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard let activity = currentActivity else { return }

            let finalState = ParadiseIDEAttributes.ContentState(
                fileName: "Session Ended",
                language: "",
                lineCount: 0,
                charCount: 0,
                codingSeconds: codingSeconds,
                themeName: "",
                petEmoji: "🌴",
                isDirty: false
            )

            Task {
                await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .after(.now + 5))
                self.currentActivity = nil
                self.activityID = nil
            }
        }
        #endif
    }
}
