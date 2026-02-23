import SwiftUI

// MARK: - Tab Definition

enum AppTab: Int, CaseIterable {
    case levels
    case duels
    case dailyChallenge
    case profile

    var title: String {
        switch self {
        case .levels:          return "Levels"
        case .duels:           return "Duels"
        case .dailyChallenge:  return "Daily"
        case .profile:         return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .levels:         return "star.fill"
        case .duels:          return "person.2"
        case .dailyChallenge: return "calendar"
        case .profile:        return "person.fill"
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedTab: AppTab  = .levels
    @State private var showLoginSheet       = false
    @State private var pendingTab: AppTab?  = nil

    private var theme: AppTheme { themeManager.current }

    // MARK: Layout Constants
    private enum Layout {
        static let headerHeight: CGFloat   = 58
        static let headerTileSize: CGFloat = 36
        static let headerSpacing: CGFloat  = 4
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Persistent Logo Header
            ZStack {
                theme.backgroundSecondary
                    .ignoresSafeArea(edges: .top)

                LogoTilesView(
                    tileSize: Layout.headerTileSize,
                    spacing:  Layout.headerSpacing,
                    animated: false
                )
                .padding(.vertical, 10)
            }
            .frame(height: Layout.headerHeight)
            .overlay(alignment: .bottom) {
                Divider()
            }

            TabView(selection: $selectedTab) {

            // MARK: Levels
            LevelsView()
                .tabItem {
                    Label(AppTab.levels.title, systemImage: AppTab.levels.icon)
                }
                .tag(AppTab.levels)

            // MARK: Duels (auth-gated)
            DuelsView(showLoginSheet: $showLoginSheet)
                .tabItem {
                    Label(AppTab.duels.title, systemImage: AppTab.duels.icon)
                }
                .tag(AppTab.duels)

            // MARK: Daily Challenge
            DailyChallengeView()
                .tabItem {
                    Label(AppTab.dailyChallenge.title, systemImage: AppTab.dailyChallenge.icon)
                }
                .tag(AppTab.dailyChallenge)

            // MARK: Profile
            ProfileView()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
        }
        .tint(theme.tabBarSelected)
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(reason: "to challenge other players")
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
        .onChange(of: authManager.isAuthenticated) { _ in
            // If user just signed in from the login sheet, keep them on Duels
        }

        } // end VStack
        .ignoresSafeArea(edges: .bottom)
    }
}
