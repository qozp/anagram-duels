import Foundation
import AuthenticationServices
import Supabase

/// Handles Apple Sign-In flow.
final class AuthService: NSObject {

    static let shared = AuthService()

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    private var appleSignInContinuation: CheckedContinuation<(token: String, displayName: String?), Error>?

    private override init() { super.init() }

    // MARK: - Apple Sign-In

    /// Presents the Apple Sign-In sheet and returns a Supabase session + the user's display name.
    /// Apple only provides the full name on the very first sign-in for a given device.
    @MainActor
    func signInWithApple() async throws -> (session: Session, displayName: String?) {
        let result = try await requestAppleCredential()
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: result.token)
        )
        return (session, result.displayName)
    }

    private func requestAppleCredential() async throws -> (token: String, displayName: String?) {
        return try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request  = provider.createRequest()
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
        get async { try? await supabase.auth.user().id }
    }

    func currentSession() async throws -> Session? {
        try await supabase.auth.session
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
            let tokenData  = credential.identityToken,
            let token      = String(data: tokenData, encoding: .utf8)
        else {
            appleSignInContinuation?.resume(throwing: AuthError.invalidCredential)
            appleSignInContinuation = nil
            return
        }

        // Apple only sends fullName on the first authorisation — capture it while we can
        let displayName: String? = {
            let parts = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }()

        appleSignInContinuation?.resume(returning: (token: token, displayName: displayName))
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
        UIApplication.shared.connectedScenes
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
