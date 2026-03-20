import SwiftUI

// MARK: - Theme Definition

struct ParadiseTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let backgroundColors: [Color]
    let accent: Color
    let accent2: Color
    let surface: Color
    let surfaceBorder: Color
    let textColor: Color
    let mutedColor: Color
    let petEmoji: String
    let particles: [String]
    let ambientLabel: String

    static func == (lhs: ParadiseTheme, rhs: ParadiseTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - All Themes

extension ParadiseTheme {

    static let ocean = ParadiseTheme(
        id: "ocean",
        name: "Deep Ocean",
        backgroundColors: [
            Color(red: 0.04, green: 0.09, blue: 0.16),
            Color(red: 0.05, green: 0.14, blue: 0.27),
            Color(red: 0.04, green: 0.24, blue: 0.42),
            Color(red: 0.10, green: 0.32, blue: 0.46)
        ],
        accent: Color(red: 0.00, green: 0.83, blue: 1.00),
        accent2: Color(red: 0.00, green: 0.60, blue: 0.80),
        surface: Color(red: 0.04, green: 0.12, blue: 0.24).opacity(0.85),
        surfaceBorder: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.18),
        textColor: Color(red: 0.72, green: 0.91, blue: 1.00),
        mutedColor: Color(red: 0.35, green: 0.60, blue: 0.71),
        petEmoji: "🐠",
        particles: ["🫧", "🫧", "🐚", "🌊", "🫧"],
        ambientLabel: "Ocean Waves"
    )

    static let beach = ParadiseTheme(
        id: "beach",
        name: "Golden Beach",
        backgroundColors: [
            Color(red: 0.10, green: 0.04, blue: 0.18),
            Color(red: 0.18, green: 0.11, blue: 0.41),
            Color(red: 0.78, green: 0.38, blue: 0.04),
            Color(red: 0.91, green: 0.63, blue: 0.13)
        ],
        accent: Color(red: 1.00, green: 0.70, blue: 0.28),
        accent2: Color(red: 1.00, green: 0.55, blue: 0.00),
        surface: Color(red: 0.12, green: 0.06, blue: 0.22).opacity(0.85),
        surfaceBorder: Color(red: 1.00, green: 0.70, blue: 0.28).opacity(0.20),
        textColor: Color(red: 1.00, green: 0.88, blue: 0.63),
        mutedColor: Color(red: 0.69, green: 0.50, blue: 0.38),
        petEmoji: "🦀",
        particles: ["🌴", "✨", "🐚", "🌊", "🌴"],
        ambientLabel: "Beach Breeze"
    )

    static let hawaii = ParadiseTheme(
        id: "hawaii",
        name: "Hawaii",
        backgroundColors: [
            Color(red: 0.05, green: 0.11, blue: 0.16),
            Color(red: 0.10, green: 0.16, blue: 0.10),
            Color(red: 0.18, green: 0.35, blue: 0.11),
            Color(red: 0.48, green: 0.21, blue: 0.06)
        ],
        accent: Color(red: 0.49, green: 0.99, blue: 0.00),
        accent2: Color(red: 0.20, green: 0.80, blue: 0.20),
        surface: Color(red: 0.04, green: 0.10, blue: 0.06).opacity(0.85),
        surfaceBorder: Color(red: 0.49, green: 0.99, blue: 0.00).opacity(0.18),
        textColor: Color(red: 0.78, green: 1.00, blue: 0.69),
        mutedColor: Color(red: 0.35, green: 0.54, blue: 0.31),
        petEmoji: "🦜",
        particles: ["🌺", "🌿", "🦋", "🌸", "🌴"],
        ambientLabel: "Tropical Birds"
    )

    static let sunset = ParadiseTheme(
        id: "sunset",
        name: "Sunset Palms",
        backgroundColors: [
            Color(red: 0.04, green: 0.04, blue: 0.10),
            Color(red: 0.10, green: 0.04, blue: 0.19),
            Color(red: 0.35, green: 0.04, blue: 0.31),
            Color(red: 1.00, green: 0.25, blue: 0.13)
        ],
        accent: Color(red: 1.00, green: 0.43, blue: 0.71),
        accent2: Color(red: 1.00, green: 0.13, blue: 0.56),
        surface: Color(red: 0.08, green: 0.02, blue: 0.12).opacity(0.85),
        surfaceBorder: Color(red: 1.00, green: 0.43, blue: 0.71).opacity(0.20),
        textColor: Color(red: 1.00, green: 0.82, blue: 0.91),
        mutedColor: Color(red: 0.63, green: 0.31, blue: 0.50),
        petEmoji: "🦩",
        particles: ["🌅", "✨", "🌴", "💫", "🌸"],
        ambientLabel: "Evening Breeze"
    )

    static let all: [ParadiseTheme] = [.ocean, .beach, .hawaii, .sunset]
}
