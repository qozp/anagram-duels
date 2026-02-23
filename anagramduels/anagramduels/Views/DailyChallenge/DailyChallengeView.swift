import SwiftUI

struct DailyChallengeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundPrimary.ignoresSafeArea()

                // TODO: Replace with daily challenge board
                ContentUnavailableView {
                    Label("Today's Challenge", systemImage: "calendar")
                        .foregroundColor(theme.textPrimary)
                } description: {
                    Text(todayFormatted)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .navigationTitle("Daily Challenge")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
