import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.grid.3x2.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)
                    Text("Anagram Duels")
                        .font(.largeTitle.bold())
                    Text("Build words. Beat friends.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Auth options
                VStack(spacing: 14) {
                    Button {
                        Task { await authVM.signInWithApple() }
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign in with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.primary)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(14)
                    }
                    .disabled(authVM.isLoading)

                    Text("Sign in to play multiplayer, track stats, and save your progress across devices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                if authVM.isLoading {
                    ProgressView()
                        .padding(.top, 16)
                }

                Spacer(minLength: 48)
            }
        }
    }
}
