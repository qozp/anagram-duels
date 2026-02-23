import SwiftUI

// MARK: - Theme Identifier

enum ThemeID: String, CaseIterable, Identifiable, Codable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark:  return "Dark"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        }
    }
}

// MARK: - Color Scheme Preference

enum ColorSchemePref: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .system: return "System"
        }
    }

    var resolved: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }
}

// MARK: - App Theme

struct AppTheme {
    // Background
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundCard: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textOnAccent: Color

    // Accent / Brand
    let accentPrimary: Color
    let accentSecondary: Color

    // Word Tiles
    let tileBackground: Color
    let tileBackgroundSelected: Color
    let tileBackgroundUsed: Color
    let tileBackgroundCorrect: Color
    let tileBackgroundWrong: Color
    let tileBorder: Color
    let tileText: Color
    let tileTextSelected: Color

    // Tab Bar
    let tabBarBackground: Color
    let tabBarSelected: Color
    let tabBarUnselected: Color

    // Buttons
    let buttonPrimary: Color
    let buttonPrimaryText: Color
    let buttonSecondary: Color
    let buttonSecondaryText: Color
    let buttonDestructive: Color

    // Dividers / Chrome
    let divider: Color
    let shadow: Color
}

// MARK: - Built-in Themes

extension AppTheme {

    static let light = AppTheme(
        backgroundPrimary:        Color(hex: "#F5F5F7"),
        backgroundSecondary:      Color(hex: "#FFFFFF"),
        backgroundCard:           Color(hex: "#FFFFFF"),

        textPrimary:              Color(hex: "#1C1C1E"),
        textSecondary:            Color(hex: "#6E6E73"),
        textOnAccent:             Color(hex: "#FFFFFF"),

        accentPrimary:            Color(hex: "#5E5CE6"),
        accentSecondary:          Color(hex: "#30D158"),

        tileBackground:           Color(hex: "#FFFFFF"),
        tileBackgroundSelected:   Color(hex: "#5E5CE6"),
        tileBackgroundUsed:       Color(hex: "#D1D1D6"),
        tileBackgroundCorrect:    Color(hex: "#30D158"),
        tileBackgroundWrong:      Color(hex: "#FF453A"),
        tileBorder:               Color(hex: "#C7C7CC"),
        tileText:                 Color(hex: "#1C1C1E"),
        tileTextSelected:         Color(hex: "#FFFFFF"),

        tabBarBackground:         Color(hex: "#FFFFFF"),
        tabBarSelected:           Color(hex: "#5E5CE6"),
        tabBarUnselected:         Color(hex: "#8E8E93"),

        buttonPrimary:            Color(hex: "#5E5CE6"),
        buttonPrimaryText:        Color(hex: "#FFFFFF"),
        buttonSecondary:          Color(hex: "#E5E5EA"),
        buttonSecondaryText:      Color(hex: "#1C1C1E"),
        buttonDestructive:        Color(hex: "#FF453A"),

        divider:                  Color(hex: "#C6C6C8"),
        shadow:                   Color.black.opacity(0.08)
    )

    static let dark = AppTheme(
        backgroundPrimary:        Color(hex: "#1C1C1E"),
        backgroundSecondary:      Color(hex: "#2C2C2E"),
        backgroundCard:           Color(hex: "#3A3A3C"),

        textPrimary:              Color(hex: "#F5F5F7"),
        textSecondary:            Color(hex: "#8E8E93"),
        textOnAccent:             Color(hex: "#FFFFFF"),

        accentPrimary:            Color(hex: "#7B79FF"),
        accentSecondary:          Color(hex: "#30D158"),

        tileBackground:           Color(hex: "#3A3A3C"),
        tileBackgroundSelected:   Color(hex: "#7B79FF"),
        tileBackgroundUsed:       Color(hex: "#48484A"),
        tileBackgroundCorrect:    Color(hex: "#30D158"),
        tileBackgroundWrong:      Color(hex: "#FF453A"),
        tileBorder:               Color(hex: "#545456"),
        tileText:                 Color(hex: "#F5F5F7"),
        tileTextSelected:         Color(hex: "#FFFFFF"),

        tabBarBackground:         Color(hex: "#2C2C2E"),
        tabBarSelected:           Color(hex: "#7B79FF"),
        tabBarUnselected:         Color(hex: "#636366"),

        buttonPrimary:            Color(hex: "#7B79FF"),
        buttonPrimaryText:        Color(hex: "#FFFFFF"),
        buttonSecondary:          Color(hex: "#3A3A3C"),
        buttonSecondaryText:      Color(hex: "#F5F5F7"),
        buttonDestructive:        Color(hex: "#FF453A"),

        divider:                  Color(hex: "#38383A"),
        shadow:                   Color.black.opacity(0.3)
    )

    static func theme(for pref: ColorSchemePref, systemIsDark: Bool) -> AppTheme {
        switch pref {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return systemIsDark ? .dark : .light
        }
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
