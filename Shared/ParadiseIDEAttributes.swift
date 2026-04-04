import ActivityKit
import Foundation

@available(iOS 16.2, *)
public struct ParadiseIDEAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var fileName: String
        public var lineCount: Int
        public var language: String
        public var status: String
        public var buildProgress: Double
        public var aiActive: Bool
        public var themeName: String
        public var tabCount: Int
        public var lastAction: String

        public init(fileName: String, lineCount: Int, language: String, status: String,
                    buildProgress: Double, aiActive: Bool, themeName: String,
                    tabCount: Int, lastAction: String) {
            self.fileName = fileName
            self.lineCount = lineCount
            self.language = language
            self.status = status
            self.buildProgress = buildProgress
            self.aiActive = aiActive
            self.themeName = themeName
            self.tabCount = tabCount
            self.lastAction = lastAction
        }
    }

    public var projectName: String

    public init(projectName: String) {
        self.projectName = projectName
    }
}
