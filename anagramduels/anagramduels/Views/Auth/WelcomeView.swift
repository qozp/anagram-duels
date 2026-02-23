import SwiftUI
import AuthenticationServices

// MARK: - Welcome View

struct WelcomeView: View {
    var onContinue: (() -> Void)? = nil // optional closure
    
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: AppTheme { themeManager.current }

    // MARK: Layout Constants
    private enum Layout {
        static let logoSize: CGFloat          = 96
        static let tileSize: CGFloat          = 52
        static let tileCornerRadius: CGFloat  = 10
        static let tileSpacing: CGFloat       = 8
        static let buttonHeight: CGFloat      = 54
        static let buttonCornerRadius: CGFloat = 14
        static let verticalPadding: CGFloat   = 40
    }

    var body: some View {
        ZStack {
            theme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo / Title
                VStack(spacing: 20) {
                    // Animated letter tiles spelling "DUEL"
                    LogoTilesView(tileSize: 56, spacing: Layout.tileSpacing, animated: true)

                    VStack(spacing: 6) {
                        Text("Anagram Duels")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)

                        Text("Build words. Beat your rivals.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                // MARK: Auth Buttons
                VStack(spacing: 14) {

                    // Apple Sign-In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        authManager.startAppleSignIn()
                        onContinue?()
                    }
                    .signInWithAppleButtonStyle(
                        themeManager.colorSchemePref == .dark ? .white : .black
                    )
                    .frame(height: Layout.buttonHeight)
                    .cornerRadius(Layout.buttonCornerRadius)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(theme.divider)
                            .frame(height: 1)
                        Text("or")
                            .font(.footnote)
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, 10)
                        Rectangle()
                            .fill(theme.divider)
                            .frame(height: 1)
                    }

                    // Guest
                    Button {
                        authManager.continueAsGuest()
                        onContinue?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                            Text("Play as Guest")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundColor(theme.buttonSecondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(theme.buttonSecondary)
                        .cornerRadius(Layout.buttonCornerRadius)
                    }

                    Text("Guest progress is saved on this device only.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, Layout.verticalPadding)
            }

            // Loading overlay
            if authManager.isLoading {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .alert("Sign-In Error", isPresented: Binding(
            get:  { authManager.authError != nil },
            set:  { if !$0 { authManager.authError = nil } }
        )) {
            Button("OK", role: .cancel) { authManager.authError = nil }
        } message: {
            Text(authManager.authError ?? "")
        }
    }
}
