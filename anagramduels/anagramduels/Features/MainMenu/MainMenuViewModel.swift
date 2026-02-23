import Foundation

@MainActor
final class MainMenuViewModel: ObservableObject {

    @Published private(set) var isLoading = false

    // MARK: - Dependencies
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Actions

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        await authService.signOut()
    }
}
