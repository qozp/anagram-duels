import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: AppTheme { themeManager.current }
    private var isReadOnly: Bool { authManager.isGuest }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: Avatar + Identity
                        ProfileHeaderView(isGuest: authManager.isGuest)

                        if isReadOnly {
                            // Guest nudge
                            GuestProfileBanner()
                        }

                        // MARK: Stats Section
                        ProfileStatsSectionView(isReadOnly: isReadOnly)

                        // MARK: Account / Settings (authenticated only shown fully)
                        ProfileMenuSection()

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Profile Header

private struct ProfileHeaderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let isGuest: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: isGuest ? "person.fill.questionmark" : "person.fill")
                    .font(.system(size: 38))
                    .foregroundColor(theme.accentPrimary)
            }

            VStack(spacing: 4) {
                Text(isGuest ? "Guest Player" : "Your Name")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(isGuest ? "Playing without an account" : "Member since 2025")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - Guest Banner

private struct GuestProfileBanner: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    @State private var showLogin = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(theme.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Progress not backed up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Text("Sign in to save your stats across devices.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Button("Sign In") { showLogin = true }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.accentPrimary)
        }
        .padding(14)
        .background(theme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.divider, lineWidth: 1))
        .padding(.horizontal, 20)
        .sheet(isPresented: $showLogin) {
            LoginSheet(reason: "to save your progress")
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Stats Section

private struct ProfileStatsSectionView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let isReadOnly: Bool

    // TODO: Replace with real stats from Supabase
    private let placeholderStats: [(label: String, value: String, icon: String)] = [
        ("Games Played", "—",  "gamecontroller.fill"),
        ("Best Score",   "—",  "trophy.fill"),
        ("Win Rate",     "—",  "percent"),
        ("Streak",       "—",  "flame.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Statistics")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(placeholderStats, id: \.label) { stat in
                    StatCard(label: stat.label, value: stat.value, icon: stat.icon)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct StatCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.accentPrimary)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.divider, lineWidth: 1))
    }
}

// MARK: - Profile Menu Section

private struct ProfileMenuSection: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Account")

            VStack(spacing: 0) {
                NavigationLink {
                    SettingsView()
                        .environmentObject(themeManager)
                        .environmentObject(authManager)
                } label: {
                    MenuRow(icon: "gearshape.fill",
                            label: "Settings",
                            color: theme.accentPrimary)
                }

                Divider().padding(.leading, 54)

                MenuRow(icon: "questionmark.circle.fill",
                        label: "Help & Support",
                        color: theme.accentSecondary)

                if authManager.isAuthenticated {
                    Divider().padding(.leading, 54)

                    Button {
                        authManager.signOut()
                    } label: {
                        MenuRow(icon: "rectangle.portrait.and.arrow.right",
                                label: "Sign Out",
                                color: theme.buttonDestructive,
                                isDestructive: true)
                    }
                }
            }
            .background(theme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.divider, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Shared Sub-views

private struct SectionHeader: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, 24)
    }
}

private struct MenuRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let icon:          String
    let label:         String
    let color:         Color
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(color)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 16))
                .foregroundColor(isDestructive ? color : theme.textPrimary)

            Spacer()

            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textSecondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
