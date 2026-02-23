import SwiftUI

/// Root gating view — shows Auth or the main NavigationStack
/// based on authentication state.
struct RootView: View {

    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        Group {
            if authService.isAuthenticated {
                NavigationStack(path: $router.path) {
                    MainMenuView()
                        .navigationDestination(for: AppRouter.Destination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: authService.isAuthenticated)
    }

    @ViewBuilder
    private func destinationView(for destination: AppRouter.Destination) -> some View {
        switch destination {
        case .mainMenu:
            MainMenuView()
        case .game(let matchID):
            GameView(matchID: matchID)
        case .profile:
            ProfileView()
        case .levels:
            LevelsView()
        case .settings:
            SettingsView()
        case .challengeFriend:
            ChallengeFriendView()
        }
    }
}
