import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                // User info
                if let user = vm.user {
                    Section {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.guestFlag ? "Guest" : "Apple Sign-In")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Stats
                if let stats = vm.globalStats {
                    Section("Stats") {
                        StatRow(label: "Total Games", value: "\(stats.totalGames)")
                        StatRow(label: "Wins", value: "\(stats.wins)")
                        StatRow(label: "Losses", value: "\(stats.losses)")
                        StatRow(label: "Win Rate", value: String(format: "%.0f%%", stats.winRate * 100))
                        StatRow(label: "Current Streak", value: "\(stats.currentStreak)")
                        StatRow(label: "Longest Streak", value: "\(stats.longestStreak)")
                    }
                }

                // Navigation
                Section {
                    NavigationLink("Friends") {
                        FriendsView()
                    }
                    NavigationLink("Settings") {
                        SettingsView()
                            .environmentObject(vm)
                            .environmentObject(authVM)
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        Task { await authVM.signOut() }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .task {
                if let id = authVM.currentUserID {
                    await vm.loadProfile(userID: id)
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

// MARK: - Friends View
struct FriendsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    @State private var pendingRequests: [FriendModel] = []

    var body: some View {
        List {
            if !multiplayerVM.friendsList.isEmpty {
                Section("Friends") {
                    ForEach(multiplayerVM.friendsList) { friend in
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                            Text(friend.username)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Friends")
        .task {
            if let id = authVM.currentUserID {
                await multiplayerVM.loadFriends(userID: id)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var selectedTheme: AppConfig.ThemeMode = .system
    @State private var notificationsOn = true
    @State private var showUsernameEditor = false
    @State private var newUsername = ""

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(AppConfig.ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .onChange(of: selectedTheme) { _, mode in
                    guard let id = authVM.currentUserID else { return }
                    Task { await vm.updateTheme(mode, userID: id) }
                }
            }

            Section("Notifications") {
                Toggle("Game notifications", isOn: $notificationsOn)
                    .onChange(of: notificationsOn) { _, enabled in
                        guard let id = authVM.currentUserID else { return }
                        Task { await vm.updateNotifications(enabled: enabled, userID: id) }
                    }
            }

            Section("Account") {
                Button("Change Username") { showUsernameEditor = true }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            selectedTheme = vm.user?.themeMode ?? .system
            notificationsOn = vm.user?.notificationsEnabled ?? true
        }
        .alert("Change Username", isPresented: $showUsernameEditor) {
            TextField("New username", text: $newUsername)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Save") {
                guard let id = authVM.currentUserID else { return }
                Task { try? await vm.updateUsername(newUsername, userID: id) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
