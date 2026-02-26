import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var singleplayerVM = SingleplayerViewModel()
    @StateObject private var multiplayerVM  = MultiplayerViewModel()
    @StateObject private var dailyVM        = DailyViewModel()
    @StateObject private var profileVM      = ProfileViewModel()

    var body: some View {
        TabView {
            SingleplayerHomeView()
                .environmentObject(singleplayerVM)
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            multiplayerTab

            DailyView()
                .environmentObject(dailyVM)
                .tabItem { Label("Daily", systemImage: "calendar") }

            ProfileView()
                .environmentObject(profileVM)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.accentColor)
        .onAppear { loadInitialData() }
        .onChange(of: authVM.isAuthenticated) { _, isAuth in
            if isAuth { loadInitialData() }
        }
    }

    @ViewBuilder
    private var multiplayerTab: some View {
        if authVM.isAuthenticated {
            MultiplayerInboxView()
                .environmentObject(multiplayerVM)
                .tabItem { Label("Multiplayer", systemImage: "person.2.fill") }
        } else {
            SignInPromptView()
                .tabItem { Label("Multiplayer", systemImage: "person.2.fill") }
        }
    }

    private func loadInitialData() {
        guard let userID = authVM.currentUserID else { return }
        Task {
            await dailyVM.loadToday(userID: userID)
            await profileVM.loadProfile(userID: userID)
            await multiplayerVM.loadInbox(userID: userID)
            await multiplayerVM.loadFriends(userID: userID)
        }
    }
}

// MARK: - Sign In Prompt (shown on Multiplayer tab for guests)
struct SignInPromptView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Multiplayer")
                    .font(.title.bold())
                Text("Sign in with Apple to challenge friends,\ntrack stats, and save your progress.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

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
            .padding(.horizontal, 40)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if authVM.isLoading {
                ProgressView()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
