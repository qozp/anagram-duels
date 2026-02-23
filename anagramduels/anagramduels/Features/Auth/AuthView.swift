import SwiftUI
import AuthenticationServices

struct AuthView: View {

    @EnvironmentObject private var authService: AuthService
    @State private var mode: AuthMode = .signIn

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            Color.adBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo / title
                    VStack(spacing: 8) {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.adPrimary)

                        Text("Anagram Duels")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.adTextPrimary)

                        Text("Challenge friends. Battle words.")
                            .font(.subheadline)
                            .foregroundStyle(Color.adTextSecondary)
                    }
                    .padding(.top, 48)

                    // Mode picker
                    Picker("Mode", selection: $mode) {
                        Text("Sign In").tag(AuthMode.signIn)
                        Text("Create Account").tag(AuthMode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Email form
                    EmailAuthForm(mode: mode)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(Color.adTextSecondary.opacity(0.3))
                        Text("or").font(.caption).foregroundStyle(Color.adTextSecondary)
                        Rectangle().frame(height: 1).foregroundStyle(Color.adTextSecondary.opacity(0.3))
                    }
                    .padding(.horizontal)

                    // Sign in with Apple
                    AppleSignInButton()
                        .padding(.horizontal)

                    // Error
                    if let error = authService.authError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.adError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Email Auth Form
private struct EmailAuthForm: View {

    let mode: AuthView.AuthMode

    @EnvironmentObject private var authService: AuthService
    @State private var email    = ""
    @State private var password = ""
    @State private var username = ""

    var body: some View {
        VStack(spacing: 16) {
            if mode == .signUp {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .adTextFieldStyle()
            }

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .adTextFieldStyle()

            SecureField("Password", text: $password)
                .textContentType(mode == .signUp ? .newPassword : .password)
                .adTextFieldStyle()

            Button(action: submit) {
                if authService.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(mode == .signUp ? "Create Account" : "Sign In")
                }
            }
            .adPrimaryButtonStyle()
            .disabled(authService.isLoading || !isFormValid)
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: AppConfig.UI.animationDuration), value: mode)
    }

    private var isFormValid: Bool {
        let baseValid = !email.isEmpty && password.count >= 6
        return mode == .signUp ? baseValid && !username.isEmpty : baseValid
    }

    private func submit() {
        Task {
            if mode == .signUp {
                await authService.signUp(email: email, password: password, username: username)
            } else {
                await authService.signIn(email: email, password: password)
            }
        }
    }
}

// MARK: - Apple Sign In Button
private struct AppleSignInButton: View {

    @EnvironmentObject private var authService: AuthService

    var body: some View {
        SignInWithAppleButton(.continue) { request in
            let hashedNonce         = authService.prepareAppleSignIn()
            request.requestedScopes = [.fullName, .email]
            request.nonce           = hashedNonce
        } onCompletion: { result in
            Task {
                switch result {
                case .success(let authorization):
                    await authService.handleAppleSignIn(authorization)
                case .failure(let error):
                    print("[AppleSignIn] Error: \(error)")
                }
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: AppConfig.UI.primaryButtonHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
    }
}

// MARK: - TextField Style Extension
private extension View {
    func adTextFieldStyle() -> some View {
        self
            .padding()
            .background(Color.adSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(Color.adTextSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}
