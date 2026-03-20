import SwiftUI
import Combine

// MARK: - Terminal Line

struct TerminalLine: Identifiable {
    enum Kind { case output, error, input, info, banner, system }

    let id = UUID()
    let raw: String          // raw text, may contain ANSI codes
    let kind: Kind
    let timestamp: Date

    init(_ raw: String, kind: Kind = .output, at: Date = .now) {
        // Strip \r so text renders cleanly in SwiftUI
        self.raw = raw.replacingOccurrences(of: "\r\n", with: "\n")
                      .replacingOccurrences(of: "\r", with: "\n")
        self.kind = kind
        self.timestamp = at
    }

    var defaultColor: Color {
        switch kind {
        case .error:   return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .input:   return Color(red: 0.4,  green: 0.9,  blue: 1.0)
        case .info:    return Color(red: 0.6,  green: 0.85, blue: 1.0)
        case .banner:  return Color(red: 0.5,  green: 1.0,  blue: 0.8)
        case .system:  return Color(red: 0.7,  green: 0.7,  blue: 0.7)
        case .output:  return Color(red: 0.88, green: 0.92, blue: 1.0)
        }
    }
}

// MARK: - Terminal Buffer

/// Manages the scrollback buffer, current working directory,
/// and exposes the rendered line list to SwiftUI views.
@MainActor
final class TerminalBuffer: ObservableObject {

    @Published var lines: [TerminalLine] = []
    @Published var currentDirectory: String = "~"
    @Published var isRunning: Bool = false     // subprocess currently active

    private let maxLines: Int

    init(maxLines: Int = 2000) {
        self.maxLines = maxLines
    }

    // MARK: - Append

    func append(_ raw: String, kind: TerminalLine.Kind = .output) {
        // Split on newlines so each line is individually selectable
        let chunks = raw.components(separatedBy: "\n")
        for (i, chunk) in chunks.enumerated() {
            // Skip the trailing empty chunk from a trailing \n
            if i == chunks.count - 1 && chunk.isEmpty { continue }
            lines.append(TerminalLine(chunk, kind: kind))
        }
        trim()
    }

    func appendInput(_ cmd: String) {
        lines.append(TerminalLine(cmd, kind: .input))
        trim()
    }

    func appendSystem(_ text: String) {
        lines.append(TerminalLine(text, kind: .system))
        trim()
    }

    func appendBanner(_ text: String) {
        let chunks = text.components(separatedBy: "\n")
        for chunk in chunks where !chunk.isEmpty {
            lines.append(TerminalLine(chunk, kind: .banner))
        }
        trim()
    }

    // MARK: - Control

    func clear() {
        lines.removeAll()
    }

    func setDirectory(_ dir: String) {
        currentDirectory = dir
    }

    // MARK: - Private

    private func trim() {
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }
}
