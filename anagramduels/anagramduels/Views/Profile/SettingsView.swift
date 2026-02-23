import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthManager

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        ZStack {
            theme.backgroundPrimary.ignoresSafeArea()

            List {

                // MARK: Appearance
                Section {
                    AppearancePickerRow()
                } header: {
                    Text("Appearance")
                        .foregroundColor(theme.textSecondary)
                }

                // MARK: Tile Preview
                Section {
                    TilePreviewRow()
                } header: {
                    Text("Word Tile Preview")
                        .foregroundColor(theme.textSecondary)
                }

                // MARK: Game Settings (placeholder)
                Section {
                    SettingsToggleRow(
                        icon: "speaker.wave.2.fill",
                        label: "Sound Effects",
                        color: theme.accentPrimary,
                        isOn: .constant(true)
                    )
                    SettingsToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        label: "Haptics",
                        color: theme.accentSecondary,
                        isOn: .constant(true)
                    )
                } header: {
                    Text("Game")
                        .foregroundColor(theme.textSecondary)
                }

                // MARK: About
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.appVersionString)
                            .foregroundColor(theme.textSecondary)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(theme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundPrimary)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Appearance Picker Row

private struct AppearancePickerRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Scheme")
                .font(.system(size: 15))
                .foregroundColor(theme.textPrimary)

            HStack(spacing: 10) {
                ForEach(ColorSchemePref.allCases) { pref in
                    AppearanceOptionButton(pref: pref,
                                          isSelected: themeManager.colorSchemePref == pref)
                    {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.colorSchemePref = pref
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(theme.backgroundCard)
    }
}

private struct AppearanceOptionButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let pref:       ColorSchemePref
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? theme.accentPrimary : theme.textSecondary)

                Text(pref.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? theme.accentPrimary : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? theme.accentPrimary.opacity(0.1)
                    : theme.backgroundSecondary
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? theme.accentPrimary : theme.divider, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch pref {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Tile Preview Row

private struct TilePreviewRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    private let sampleLetters = ["A", "N", "G", "R", "A", "M"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(sampleLetters.enumerated()), id: \.offset) { index, letter in
                WordTileView(
                    letter: letter,
                    state: tileState(for: index)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(theme.backgroundCard)
    }

    private func tileState(for index: Int) -> WordTileState {
        switch index {
        case 0: return .normal
        case 1: return .selected
        case 2: return .correct
        case 3: return .wrong
        case 4: return .used
        default: return .normal
        }
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let icon:  String
    let label: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text(label)
                    .foregroundColor(theme.textPrimary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
        }
        .tint(theme.accentPrimary)
        .listRowBackground(theme.backgroundCard)
    }
}

// MARK: - Bundle Helper

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
