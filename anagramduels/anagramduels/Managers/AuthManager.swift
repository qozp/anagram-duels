import SwiftUI
import AuthenticationServices
import Combine

// MARK: - Auth State

enum AuthState: Equatable {
    case unauthenticated        // Fresh launch, no session
    case guest                  // Playing without an account
    case authenticated(userID: String)
}

// MARK: - AuthManager

final class AuthManager: NSObject, ObservableObject {

    // MARK: Persistence Keys
    private enum Keys {
        static let authState    = "authState"
        static let guestMode    = "guestMode"
        static let userID       = "userID"
    }

    // MARK: Published

    @Published private(set) var authState: AuthState = .unauthenticated
    @Published private(set) var isLoading: Bool = false
    @Published var authError: String? = nil

    // MARK: Computed Helpers

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var isGuest: Bool {
        authState == .guest
    }

    var currentUserID: String? {
        if case .authenticated(let id) = authState { return id }
        return nil
    }

    // MARK: Init

    override init() {
        super.init()
        restoreSession()
    }

    // MARK: Guest

    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: Keys.guestMode)
        UserDefaults.standard.removeObject(forKey: Keys.userID)
        authState = .guest
    }

    // MARK: Apple Sign-In

    func startAppleSignIn() {
        let provider  = ASAuthorizationAppleIDProvider()
        let request   = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate              = self
        controller.presentationContextProvider = self
        controller.performRequests()

        isLoading = true
    }

    // MARK: Sign Out

    func signOut() {
        UserDefaults.standard.removeObject(forKey: Keys.guestMode)
        UserDefaults.standard.removeObject(forKey: Keys.userID)
        authState = .unauthenticated
    }

    // MARK: Session Restore

    private func restoreSession() {
        if let savedID = UserDefaults.standard.string(forKey: Keys.userID) {
            // Validate credential is still valid with Apple
            let appleProvider = ASAuthorizationAppleIDProvider()
            appleProvider.getCredentialState(forUserID: savedID) { [weak self] state, _ in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        self?.authState = .authenticated(userID: savedID)
                    default:
                        self?.authState = .unauthenticated
                        UserDefaults.standard.removeObject(forKey: self!.Keys_userID)
                    }
                }
            }
        } else if UserDefaults.standard.bool(forKey: Keys.guestMode) {
            authState = .guest
        }
    }

    // Workaround for referencing Keys inside a closure on self
    private var Keys_userID: String { Keys.userID }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        isLoading = false
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = "Unexpected credential type."
            return
        }

        let userID = credential.user
        // TODO: Exchange identityToken with your Supabase backend for a session
        // let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
        // await supabaseClient.auth.signInWithIdToken(provider: .apple, idToken: token)

        UserDefaults.standard.set(userID, forKey: Keys.userID)
        UserDefaults.standard.removeObject(forKey: Keys.guestMode)
        authState = .authenticated(userID: userID)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        isLoading = false
        // ASAuthorizationError.canceled (1001) means the user dismissed — not a real error
        if (error as? ASAuthorizationError)?.code == .canceled { return }
        authError = error.localizedDescription
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Grab the key window safely
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
