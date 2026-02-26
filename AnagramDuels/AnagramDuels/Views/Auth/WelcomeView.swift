import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showMainTabs = false

    private enum Layout {
        static let buttonHeight: CGFloat       = 54
        static let buttonCornerRadius: CGFloat = 14
        static let bottomPadding: CGFloat      = 40
    }

    var body: some View {
        if showMainTabs {
            MainTabView()
        } else {
            welcomeContent
                .onChange(of: authVM.isAuthenticated) { _, isAuth in
                    // If Apple Sign-In completes, transition to main app
                    if isAuth {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMainTabs = true
                        }
                    }
                }
        }
    }

    private var welcomeContent: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo
                VStack(spacing: 24) {
                    LogoTilesView(animated: true)

                    VStack(spacing: 6) {
                        Text("Anagram Duels")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Build words. Beat your rivals.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // MARK: Buttons
                VStack(spacing: 14) {

                    // Native Apple Sign-In button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        Task { await authVM.signInWithApple() }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: Layout.buttonHeight)
                    .cornerRadius(Layout.buttonCornerRadius)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        Text("or")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }

                    // Guest button
                    Button {
                        authVM.continueAsGuest()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMainTabs = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                            Text("Play as Guest")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(Layout.buttonCornerRadius)
                    }

                    Text("Guest progress is saved on this device only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, Layout.bottomPadding)
            }

            // MARK: Loading overlay
            if authVM.isLoading {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .alert("Sign-In Error", isPresented: Binding(
            get:  { authVM.errorMessage != nil },
            set:  { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }
}
