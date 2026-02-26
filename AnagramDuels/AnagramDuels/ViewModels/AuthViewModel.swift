import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    enum AuthState {
        case loading
        case unauthenticated
        case guest
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
            let result = try await authService.signInWithApple()
            await fetchOrCreateUser(supabaseUserID: result.session.user.id, displayName: result.displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Guest

    func continueAsGuest() {
        state = .guest
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        do {
            if case .authenticated = state {
                try await authService.signOut()
            }
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

    var isGuest: Bool {
        if case .guest = state { return true }
        return false
    }

    // MARK: - Private Helpers

    private func fetchOrCreateUser(supabaseUserID: UUID, displayName: String? = nil) async {
        do {
            let users: [UserModel] = try await supabase
                .from("users")
                .select()
                .eq("id", value: supabaseUserID.uuidString)
                .limit(1)
                .execute()
                .value

            if let existing = users.first {
                // Apple only provides display name on first sign-in — save it if we don't have it yet
                if let name = displayName, existing.displayName == nil {
                    try? await supabase
                        .from("users")
                        .update(["display_name": name])
                        .eq("id", value: supabaseUserID.uuidString)
                        .execute()
                    var updated = existing
                    updated.displayName = name
                    state = .authenticated(user: updated)
                } else {
                    state = .authenticated(user: existing)
                }
            } else {
                let newUser = try await createUserRecord(id: supabaseUserID, displayName: displayName)
                state = .authenticated(user: newUser)
            }
        } catch {
            errorMessage = "Failed to load account: \(error.localizedDescription)"
            state = .unauthenticated
        }
    }

    private func createUserRecord(id: UUID, displayName: String?) async throws -> UserModel {
        struct NewUser: Encodable {
            let id: String
            let username: String
            let display_name: String?
            let guest_flag: Bool
            let theme_mode: String
            let notifications_enabled: Bool
        }

        let record = NewUser(
            id: id.uuidString,
            username: "user_\(UUID().uuidString.prefix(8))",
            display_name: displayName,
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
            throw NSError(domain: "AuthViewModel", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User creation failed."])
        }
        return user
    }
}
