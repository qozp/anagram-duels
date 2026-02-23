import SwiftUI

struct DuelsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    @Binding var showLoginSheet: Bool

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundPrimary.ignoresSafeArea()

                if authManager.isAuthenticated {
                    // TODO: Replace with real duels lobby
                    ContentUnavailableView {
                        Label("Duels Coming Soon", systemImage: "cross.swords")
                            .foregroundColor(theme.textPrimary)
                    } description: {
                        Text("Challenge players from around the world.")
                            .foregroundColor(theme.textSecondary)
                    }
                } else {
                    // Guest gate — prompt to sign in
                    GuestGateView(
                        icon:        "person.2",
                        title:       "Multiplayer Duels",
                        description: "Sign in to challenge friends and players worldwide.",
                        ctaLabel:    "Sign In to Play"
                    ) {
                        showLoginSheet = true
                    }
                }
            }
            .navigationTitle("Duels")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            // Immediately prompt guest when they tap the tab
            if authManager.isGuest {
                showLoginSheet = true
            }
        }
    }
}

// MARK: - Guest Gate View (reusable)

struct GuestGateView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let icon:        String
    let title:       String
    let description: String
    let ctaLabel:    String
    let onCTA:       () -> Void

    private enum Layout {
        static let buttonHeight: CGFloat       = 52
        static let buttonCornerRadius: CGFloat = 14
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(theme.accentPrimary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                onCTA()
            } label: {
                Text(ctaLabel)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.buttonPrimaryText)
                    .frame(maxWidth: 280)
                    .frame(height: Layout.buttonHeight)
                    .background(theme.buttonPrimary)
                    .cornerRadius(Layout.buttonCornerRadius)
            }
        }
        .padding()
    }
}
