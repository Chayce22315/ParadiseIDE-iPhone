import SwiftUI

// MARK: - ANSI Color/Style Parser
// Converts raw terminal output (with ANSI escape codes) into
// SwiftUI Text views with proper colors and styles.
// Used by TerminalOutputView to render server responses correctly.

struct ANSISegment {
    let text: String
    let color: Color
    let bold: Bool
    let italic: Bool
    let underline: Bool
}

enum ANSIParser {

    // Standard 16-color ANSI palette
    static func color(from code: Int, bright: Bool = false) -> Color {
        switch code {
        case 30: return bright ? Color(red:0.6,  green:0.6,  blue:0.6)  : Color(red:0.2, green:0.2, blue:0.2)
        case 31: return bright ? Color(red:1.0,  green:0.4,  blue:0.4)  : Color(red:0.8, green:0.1, blue:0.1)
        case 32: return bright ? Color(red:0.4,  green:1.0,  blue:0.4)  : Color(red:0.1, green:0.7, blue:0.1)
        case 33: return bright ? Color(red:1.0,  green:1.0,  blue:0.4)  : Color(red:0.8, green:0.7, blue:0.1)
        case 34: return bright ? Color(red:0.4,  green:0.6,  blue:1.0)  : Color(red:0.1, green:0.3, blue:0.9)
        case 35: return bright ? Color(red:1.0,  green:0.4,  blue:1.0)  : Color(red:0.7, green:0.1, blue:0.8)
        case 36: return bright ? Color(red:0.4,  green:1.0,  blue:1.0)  : Color(red:0.1, green:0.7, blue:0.8)
        case 37: return bright ? .white                                  : Color(red:0.8, green:0.8, blue:0.8)
        default: return .white
        }
    }

    // Parse a raw string with ANSI codes into segments
    static func parse(_ raw: String, defaultColor: Color = .white) -> [ANSISegment] {
        var segments: [ANSISegment] = []
        var currentColor = defaultColor
        var bold = false
        var italic = false
        var underline = false

        // Split on ESC[
        let parts = raw.components(separatedBy: "\u{1B}[")

        for (i, part) in parts.enumerated() {
            if i == 0 {
                if !part.isEmpty {
                    segments.append(ANSISegment(text: part, color: currentColor, bold: bold, italic: italic, underline: underline))
                }
                continue
            }

            // Find the 'm' terminator
            guard let mRange = part.range(of: "m") else {
                segments.append(ANSISegment(text: part, color: currentColor, bold: bold, italic: italic, underline: underline))
                continue
            }

            let codes = String(part[part.startIndex..<mRange.lowerBound])
            let remainder = String(part[mRange.upperBound...])

            // Parse semicolon-separated codes
            let codeNumbers = codes.split(separator: ";").compactMap { Int($0) }

            for code in codeNumbers {
                switch code {
                case 0:        currentColor = defaultColor; bold = false; italic = false; underline = false
                case 1:        bold = true
                case 3:        italic = true
                case 4:        underline = true
                case 22:       bold = false
                case 23:       italic = false
                case 24:       underline = false
                case 30...37:  currentColor = color(from: code)
                case 90...97:  currentColor = color(from: code - 60, bright: true)
                case 39:       currentColor = defaultColor
                default:       break
                }
            }

            if !remainder.isEmpty {
                segments.append(ANSISegment(text: remainder, color: currentColor, bold: bold, italic: italic, underline: underline))
            }
        }

        return segments
    }

    // Render segments as a single SwiftUI Text
    @MainActor
    static func render(_ raw: String, defaultColor: Color = .white, font: Font = .system(size: 12, design: .monospaced)) -> Text {
        let segments = parse(raw, defaultColor: defaultColor)
        var result = Text("")

        for seg in segments {
            var t = Text(seg.text).font(font).foregroundColor(seg.color)
            if seg.bold      { t = t.bold() }
            if seg.italic    { t = t.italic() }
            if seg.underline { t = t.underline() }
            result = result + t
        }

        return result
    }
}

// MARK: - ANSI Text View (drop-in for TerminalLine)

struct ANSITextView: View {
    let raw: String
    let defaultColor: Color
    let fontSize: CGFloat

    init(_ raw: String, defaultColor: Color = .white, fontSize: CGFloat = 12) {
        self.raw = raw
        self.defaultColor = defaultColor
        self.fontSize = fontSize
    }

    var body: some View {
        ANSIParser.render(raw, defaultColor: defaultColor,
                          font: .system(size: fontSize, design: .monospaced))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(2)
    }
}
