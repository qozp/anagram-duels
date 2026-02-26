import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileHeader
                }

                if let stats = vm.globalStats {
                    Section("Stats") {
                        StatRow(label: "Total Games",    value: "\(stats.totalGames)")
                        StatRow(label: "Wins",           value: "\(stats.wins)")
                        StatRow(label: "Losses",         value: "\(stats.losses)")
                        StatRow(label: "Win Rate",       value: String(format: "%.0f%%", stats.winRate * 100))
                        StatRow(label: "Current Streak", value: "\(stats.currentStreak)")
                        StatRow(label: "Longest Streak", value: "\(stats.longestStreak)")
                    }
                }

                Section {
                    if authVM.isAuthenticated {
                        NavigationLink("Friends") { FriendsView() }
                    }
                    NavigationLink("Settings") {
                        SettingsView()
                            .environmentObject(vm)
                            .environmentObject(authVM)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authVM.signOut() }
                    } label: {
                        Text(authVM.isGuest ? "Exit Guest Mode" : "Sign Out")
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

    @ViewBuilder
    private var profileHeader: some View {
        if authVM.isGuest {
            HStack(spacing: 14) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest")
                        .font(.headline)
                    Text("Sign in to save your progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        } else if let user = vm.user {
            NavigationLink {
                EditProfileView()
                    .environmentObject(vm)
                    .environmentObject(authVM)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        if let name = user.displayName, !name.isEmpty {
                            Text(name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("@\(user.username)")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Text("Tap to edit profile")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            HStack(spacing: 14) {
                ProgressView()
                Text("Loading…").foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var vm: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var displayName = ""
    @State private var username = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Display Name") {
                    TextField("Your name", text: $displayName)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                }
                LabeledContent("Username") {
                    TextField("username", text: $username)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            } footer: {
                Text("Username: 3–20 characters, letters, numbers, and underscores only.")
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Changes").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving || !hasChanges)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prefill() }
        .overlay(alignment: .top) {
            if showSuccess {
                Text("Profile updated!")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showSuccess)
    }

    private var hasChanges: Bool {
        displayName != (vm.user?.displayName ?? "") ||
        username    != (vm.user?.username ?? "")
    }

    private func prefill() {
        displayName = vm.user?.displayName ?? ""
        username    = vm.user?.username ?? ""
    }

    private func save() async {
        guard let userID = authVM.currentUserID else { return }
        isSaving = true
        errorMessage = nil
        do {
            if displayName != (vm.user?.displayName ?? "") {
                try await vm.updateDisplayName(displayName, userID: userID)
            }
            if username != (vm.user?.username ?? "") {
                try await vm.updateUsername(username, userID: userID)
            }
            showSuccess = true
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSuccess = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Stat Row
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

    var body: some View {
        List {
            if multiplayerVM.friendsList.isEmpty {
                ContentUnavailableView("No friends yet", systemImage: "person.2")
            } else {
                Section("Friends") {
                    ForEach(multiplayerVM.friendsList) { friend in
                        HStack {
                            Image(systemName: "person.circle").foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                if let name = friend.displayName, !name.isEmpty {
                                    Text(name).font(.body)
                                    Text("@\(friend.username)").font(.caption).foregroundColor(.secondary)
                                } else {
                                    Text("@\(friend.username)").font(.body)
                                }
                            }
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

            if authVM.isAuthenticated {
                Section("Notifications") {
                    Toggle("Game notifications", isOn: $notificationsOn)
                        .onChange(of: notificationsOn) { _, enabled in
                            guard let id = authVM.currentUserID else { return }
                            Task { await vm.updateNotifications(enabled: enabled, userID: id) }
                        }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            selectedTheme   = vm.user?.themeMode ?? .system
            notificationsOn = vm.user?.notificationsEnabled ?? true
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
