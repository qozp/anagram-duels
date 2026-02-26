import Foundation
import Combine
import Supabase

/// Drives the global authentication state. Injected as an @EnvironmentObject.
@MainActor
final class AuthViewModel: ObservableObject {

    enum AuthState {
        case loading
        case unauthenticated  // signed out, but may have passed welcome
        case authenticated(user: UserModel)
    }

    @Published private(set) var state: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let authService: AuthService
    private var supabase: SupabaseClient { SupabaseService.shared.client }

    init() {
        self.authService = AuthService.shared
        Task { await checkExistingSession() }
    }

    // MARK: - Session Restoration

    private func checkExistingSession() async {
        do {
            let session = try await supabase.auth.session
            await fetchOrCreateUser(supabaseUserID: session.user.id)
        } catch {
            state = .unauthenticated
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await authService.signInWithApple()
            await fetchOrCreateUser(supabaseUserID: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Guest (no Supabase session, local play only)

    func continueAsGuest() {
        // state stays .unauthenticated — MainTabView handles what's available
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        do {
            try await authService.signOut()
            state = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Convenience

    var currentUserID: UUID? {
        if case .authenticated(let user) = state { return user.id }
        return nil
    }

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    // MARK: - Private Helpers

    private func fetchOrCreateUser(supabaseUserID: UUID) async {
        do {
            let users: [UserModel] = try await supabase
                .from("users")
                .select()
                .eq("id", value: supabaseUserID.uuidString)
                .limit(1)
                .execute()
                .value

            if let existing = users.first {
                state = .authenticated(user: existing)
            } else {
                let newUser = try await createUserRecord(id: supabaseUserID)
                state = .authenticated(user: newUser)
            }
        } catch {
            errorMessage = "Failed to load account: \(error.localizedDescription)"
            state = .unauthenticated
        }
    }

    private func createUserRecord(id: UUID) async throws -> UserModel {
        let username = "user_\(UUID().uuidString.prefix(8))"

        struct NewUser: Encodable {
            let id: String
            let username: String
            let guest_flag: Bool
            let theme_mode: String
            let notifications_enabled: Bool
        }

        let record = NewUser(
            id: id.uuidString,
            username: username,
            guest_flag: false,
            theme_mode: AppConfig.ThemeMode.system.rawValue,
            notifications_enabled: true
        )

        try await supabase.from("users").insert(record).execute()

        let users: [UserModel] = try await supabase
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        guard let user = users.first else {
            throw NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User creation failed."])
        }
        return user
    }
}
