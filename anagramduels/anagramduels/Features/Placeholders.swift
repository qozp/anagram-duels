import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Game
// ─────────────────────────────────────────────
struct GameView: View {
    let matchID: String

    var body: some View {
        PlaceholderScreen(
            title: "Game",
            subtitle: "Match: \(matchID)",
            icon: "gamecontroller.fill"
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - Profile
// ─────────────────────────────────────────────
struct ProfileView: View {
    var body: some View {
        PlaceholderScreen(
            title: "Profile & Stats",
            subtitle: "Your wins, losses and word history",
            icon: "chart.bar.fill"
        )
        .navigationTitle("Profile")
    }
}

// ─────────────────────────────────────────────
// MARK: - Levels
// ─────────────────────────────────────────────
struct LevelsView: View {
    var body: some View {
        PlaceholderScreen(
            title: "Levels",
            subtitle: "Solo challenges with target scores",
            icon: "list.number"
        )
        .navigationTitle("Levels")
    }
}

// ─────────────────────────────────────────────
// MARK: - Settings
// ─────────────────────────────────────────────
struct SettingsView: View {
    var body: some View {
        PlaceholderScreen(
            title: "Settings",
            subtitle: "Haptics, accessibility, and more",
            icon: "gearshape.fill"
        )
        .navigationTitle("Settings")
    }
}

// ─────────────────────────────────────────────
// MARK: - Challenge Friend
// ─────────────────────────────────────────────
struct ChallengeFriendView: View {
    var body: some View {
        PlaceholderScreen(
            title: "Challenge Friend",
            subtitle: "Invite a friend to a 1v1 duel",
            icon: "person.2.fill"
        )
        .navigationTitle("Challenge")
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared Placeholder Component
// ─────────────────────────────────────────────
private struct PlaceholderScreen: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        ZStack {
            Color.adBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.adPrimary.opacity(0.3))

                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.adTextPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.adTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("Coming soon")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.adSurface)
                    .clipShape(Capsule())
                    .foregroundStyle(Color.adTextSecondary)
            }
        }
    }
}
