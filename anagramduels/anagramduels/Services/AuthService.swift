import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

/// Manages authentication state and all auth operations.
/// Exposes the current session / user so views can react.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Published State
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var isLoading = false
    @Published var authError: String?

    var isAuthenticated: Bool { currentUser != nil }

    // MARK: - Private
    private let client = SupabaseService.shared.client

    // Used for Sign in with Apple nonce verification
    private var currentNonce: String?

    // MARK: - Init
    init() {
        Task { await restoreSession() }
        observeAuthChanges()
    }

    // MARK: - Session Restore

    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            await fetchOrCreateProfile(for: session.user)
        } catch {
            // No existing session — user will see auth screen
        }
    }

    // MARK: - Auth State Observation

    private func observeAuthChanges() {
        Task {
            for await (event, session) in await client.auth.authStateChanges {
                switch event {
                case .signedIn:
                    if let user = session?.user {
                        await fetchOrCreateProfile(for: user)
                    }
                case .signedOut, .userDeleted:
                    currentUser = nil
                default:
                    break
                }
            }
        }
    }

    // MARK: - Email / Password

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            if let user = response.user {
                try await createProfile(for: user, username: username)
                await fetchOrCreateProfile(for: user)
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign in with Apple

    /// Call this to get the nonce and then trigger the Apple auth request.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleSignIn(_ authorization: ASAuthorization) async {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData   = credential.identityToken,
            let idToken     = String(data: tokenData, encoding: .utf8),
            let nonce       = currentNonce
        else {
            authError = "Apple Sign In failed — missing credentials."
            return
        }

        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Profile

    private func fetchOrCreateProfile(for user: Supabase.User) async {
        do {
            let profile: AppUser = try await client
                .from("profiles")
                .select()
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
                .value
            currentUser = profile
        } catch {
            // Profile might not exist yet (e.g. Apple Sign In first-time)
            let username = user.email?.components(separatedBy: "@").first ?? "player_\(UUID().uuidString.prefix(6))"
            try? await createProfile(for: user, username: username)
        }
    }

    private func createProfile(for user: Supabase.User, username: String) async throws {
        let newProfile = AppUser(
            id: user.id,
            username: username,
            avatarURL: nil,
            wins: 0,
            losses: 0,
            totalWordsFound: 0
        )
        try await client
            .from("profiles")
            .insert(newProfile)
            .execute()
        currentUser = newProfile
    }

    // MARK: - Nonce Helpers (for Apple Sign In)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result  = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            for random in randoms where remainingLength > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data   = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
