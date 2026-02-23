import SwiftUI
import AuthenticationServices

// MARK: - Login Sheet

/// Presented as a sheet when a guest attempts to access a feature that requires an account.
struct LoginSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss)  private var dismiss

    /// Contextual reason shown to the user (e.g. "to challenge other players")
    let reason: String

    private var theme: AppTheme { themeManager.current }

    private enum Layout {
        static let buttonHeight: CGFloat      = 54
        static let buttonCornerRadius: CGFloat = 14
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Illustration
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 56))
                        .foregroundColor(theme.accentPrimary)
                        .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text("Sign in to continue")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)

                        Text("You need an account \(reason).")
                            .font(.system(size: 15))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    VStack(spacing: 14) {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { _ in
                            authManager.startAppleSignIn()
                        }
                        .signInWithAppleButtonStyle(
                            themeManager.colorSchemePref == .dark ? .white : .black
                        )
                        .frame(height: Layout.buttonHeight)
                        .cornerRadius(Layout.buttonCornerRadius)

                        Button("Maybe Later") { dismiss() }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth { dismiss() }
        }
        .overlay {
            if authManager.isLoading {
                Color.black.opacity(0.35).ignoresSafeArea()
                ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(1.4)
            }
        }
    }
}
