import SwiftUI

extension Color {

    // MARK: - Tile Colors
    static let tileBackground  = Color("TileBackground")   // unplaced tile fill
    static let tilePlaced      = Color("TilePlaced")        // tile in word slot
    static let tileBorder      = Color("TileBorder")        // tile stroke
    static let tileText        = Color("TileText")          // letter on tile

    // MARK: - Slot Colors
    static let slotEmpty       = Color("SlotEmpty")         // empty word slot
    static let slotFilled      = Color("SlotFilled")        // word slot with tile

    // MARK: - App Chrome
    static let appBackground   = Color("AppBackground")
    static let cardBackground  = Color("CardBackground")
    static let primaryText     = Color("PrimaryText")
    static let secondaryText   = Color("SecondaryText")
    static let accent          = Color("Accent")            // primary action / timer bar

    // MARK: - Semantic
    static let successGreen    = Color("SuccessGreen")
    static let errorRed        = Color("ErrorRed")
    static let warningYellow   = Color("WarningYellow")

    // MARK: - Fallbacks (used when asset catalog entries aren't set up yet)
    static func tileBg(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.93)
    }

    static func slotBg(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.88)
    }
}

// MARK: - Timer Color Gradient
extension Color {
    /// Returns a color interpolating from green → yellow → red as `fraction` goes 0 → 1.
    static func timerColor(fractionElapsed: Double) -> Color {
        switch fractionElapsed {
        case ..<0.5: return .green
        case ..<0.75: return .yellow
        default:     return .red
        }
    }
}
