import SwiftUI
import Combine

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {

    // MARK: Persistence Keys
    private enum Keys {
        static let colorSchemePref = "colorSchemePref"
    }

    // MARK: Published

    @Published var colorSchemePref: ColorSchemePref {
        didSet {
            UserDefaults.standard.set(colorSchemePref.rawValue, forKey: Keys.colorSchemePref)
            updateTheme()
        }
    }

    @Published private(set) var current: AppTheme

    // Exposed to SwiftUI's preferredColorScheme modifier (nil = follow system)
    var resolvedColorScheme: ColorScheme? {
        colorSchemePref.resolved
    }

    // MARK: Init

    init() {
        let savedPref = UserDefaults.standard
            .string(forKey: Keys.colorSchemePref)
            .flatMap(ColorSchemePref.init(rawValue:)) ?? .system

        self.colorSchemePref = savedPref

        // Bootstrap with light; updateTheme() below will reconcile after init.
        // We can't read the system color scheme at init time without UITraitCollection,
        // so we default to light until the view tree is live.
        self.current = (savedPref == .dark) ? .dark : .light
    }

    // MARK: Update

    /// Called by ThemeObserver when the system color scheme changes.
    func systemColorSchemeChanged(_ systemIsDark: Bool) {
        updateTheme(systemIsDark: systemIsDark)
    }

    private func updateTheme(systemIsDark: Bool = false) {
        current = AppTheme.theme(for: colorSchemePref, systemIsDark: systemIsDark)
    }
}

// MARK: - ThemeObserver ViewModifier

/// Attach to the root view to keep ThemeManager in sync with the system color scheme.
struct ThemeObserverModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { newScheme in
                themeManager.systemColorSchemeChanged(newScheme == .dark)
            }
            .onAppear {
                themeManager.systemColorSchemeChanged(colorScheme == .dark)
            }
    }
}

extension View {
    func observingTheme() -> some View {
        modifier(ThemeObserverModifier())
    }
}
