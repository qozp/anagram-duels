import SwiftUI

struct LevelsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundPrimary.ignoresSafeArea()

                // TODO: Replace with level grid
                ContentUnavailableView {
                    Label("Levels Coming Soon", systemImage: "star.fill")
                        .foregroundColor(theme.textPrimary)
                } description: {
                    Text("Your solo level journey starts here.")
                        .foregroundColor(theme.textSecondary)
                }
            }
            .navigationTitle("Levels")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
