import SwiftUI

/// Drives top-level navigation for the app.
/// Screens inject and observe this via @EnvironmentObject.
final class AppRouter: ObservableObject {

    enum Destination: Hashable {
        case mainMenu
        case game(matchID: String)
        case profile
        case levels
        case settings
        case challengeFriend
    }

    @Published var path = NavigationPath()

    // MARK: - Navigation

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }
}
