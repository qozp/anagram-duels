import Foundation
import AuthenticationServices
import Supabase

/// Handles Apple Sign-In and guest authentication flows.
/// All auth state changes are observed through `SupabaseService.shared.client.auth`.
final class AuthService: NSObject {

    static let shared = AuthService()

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // Continuation captured during Apple Sign-In ASAuthorizationController flow
    private var appleSignInContinuation: CheckedContinuation<String, Error>?

    private override init() {
        super.init()
    }

    // MARK: - Apple Sign-In

    /// Initiates Apple Sign-In and returns the Supabase session on success.
    /// Throws if the user cancels or if authentication fails.
    @MainActor
    func signInWithApple() async throws -> Session {
        let idToken = try await requestAppleIDToken()
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
        return session
    }

    /// Requests an Apple ID token via `ASAuthorizationController`.
    private func requestAppleIDToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - Current Session

    var currentUserID: UUID? {
        get async {
            return try? await supabase.auth.user().id
        }
    }

    func currentSession() async throws -> Session? {
        return try await supabase.auth.session
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            appleSignInContinuation?.resume(throwing: AuthError.invalidCredential)
            appleSignInContinuation = nil
            return
        }
        appleSignInContinuation?.resume(returning: token)
        appleSignInContinuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Returns the key window for presenting the Apple Sign-In sheet
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredential
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Apple Sign-In returned an invalid credential."
        case .noActiveSession:   return "No active session. Please sign in."
        }
    }
}
