import SwiftUI

// MARK: - Color helpers (colorblind-safe palette)
extension Color {
    /// Use these named colours everywhere instead of literal values.
    static let adPrimary      = Color("Primary")       // brand accent
    static let adBackground   = Color("Background")
    static let adSurface      = Color("Surface")
    static let adSuccess      = Color("Success")       // colorblind-safe green
    static let adError        = Color("Error")         // colorblind-safe red
    static let adWarning      = Color("Warning")
    static let adTextPrimary  = Color("TextPrimary")
    static let adTextSecondary = Color("TextSecondary")
}

// MARK: - View modifiers
extension View {
    /// Applies the standard Anagram Duels card style.
    func adCardStyle() -> some View {
        self
            .background(Color.adSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    /// Primary action button style.
    func adPrimaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: AppConfig.UI.primaryButtonHeight)
            .background(Color.adPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
            .fontWeight(.semibold)
    }
}

// MARK: - String helpers
extension String {
    /// Returns true when every character in `self` can be satisfied by
    /// one occurrence of a character from the given multiset of letters.
    func canBeFormed(from letters: [Character]) -> Bool {
        var available = letters
        for char in self.lowercased() {
            guard let idx = available.firstIndex(of: char) else { return false }
            available.remove(at: idx)
        }
        return true
    }
}
