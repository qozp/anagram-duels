import SwiftUI

// MARK: - Inbox
struct MultiplayerInboxView: View {
    @EnvironmentObject var vm: MultiplayerViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.matches.isEmpty {
                    ProgressView("Loading matches…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.matches.isEmpty {
                    ContentUnavailableView(
                        "No matches yet",
                        systemImage: "envelope",
                        description: Text("Invite a friend to start a duel!")
                    )
                } else {
                    matchList
                }
            }
            .navigationTitle("Multiplayer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInvite = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showInvite) {
                InviteFriendView()
                    .environmentObject(vm)
                    .environmentObject(authVM)
            }
            .refreshable {
                if let id = authVM.currentUserID {
                    await vm.loadInbox(userID: id)
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var matchList: some View {
        List(vm.matches) { match in
            NavigationLink {
                MatchDetailView(match: match)
                    .environmentObject(vm)
                    .environmentObject(authVM)
            } label: {
                MatchRowView(match: match, currentUserID: authVM.currentUserID)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Match Row
struct MatchRowView: View {
    let match: MatchModel
    let currentUserID: UUID?

    private var opponentID: UUID? {
        guard let me = currentUserID else { return nil }
        return match.inviteSenderID == me ? match.inviteReceiverID : match.inviteSenderID
    }

    private var statusLabel: String {
        switch match.status {
        case .pending:    return "Waiting for opponent"
        case .inProgress: return "Your turn"
        case .completed:  return "Completed"
        case .canceled:   return "Canceled"
        }
    }

    private var statusColor: Color {
        switch match.status {
        case .pending:    return .orange
        case .inProgress: return .accentColor
        case .completed:  return .green
        case .canceled:   return .secondary
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.seedWord.uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.createdAt.formatted(.relative(presentation: .numeric)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Match Detail
struct MatchDetailView: View {
    let match: MatchModel
    @EnvironmentObject var vm: MultiplayerViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var mySubmission: MatchSubmissionModel?
    @State private var opponentSubmission: MatchSubmissionModel?
    @State private var isLoading = true

    private var currentUserID: UUID? { authVM.currentUserID }
    private var opponentID: UUID? {
        guard let me = currentUserID else { return nil }
        return match.inviteSenderID == me ? match.inviteReceiverID : match.inviteSenderID
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Seed word display
                        Text(match.seedWord.uppercased())
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .padding(.top)

                        // Status
                        matchStatusSection

                        // My words (always visible after submission)
                        if let sub = mySubmission {
                            submissionSection(title: "Your Words", submission: sub)
                        }

                        // Opponent words (only when match is completed)
                        if match.status == .completed, let sub = opponentSubmission {
                            submissionSection(title: "Opponent's Words", submission: sub)
                        }

                        // Play button if not yet submitted
                        if mySubmission == nil && match.status != .canceled {
                            NavigationLink {
                                GameBoardView(viewModel: GameViewModel(context: .multiplayer(match)))
                            } label: {
                                Text("Play Now")
                                    .buttonStyle(.primary)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Match")
        .task { await loadSubmissions() }
    }

    private var matchStatusSection: some View {
        HStack {
            Label(match.status.rawValue.capitalized, systemImage: statusIcon)
                .font(.subheadline)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.12))
        .cornerRadius(20)
    }

    private var statusIcon: String {
        switch match.status {
        case .pending: return "clock"
        case .inProgress: return "gamecontroller"
        case .completed: return "checkmark.circle"
        case .canceled: return "xmark.circle"
        }
    }

    private var statusColor: Color {
        switch match.status {
        case .pending:    return .orange
        case .inProgress: return .accentColor
        case .completed:  return .green
        case .canceled:   return .red
        }
    }

    private func submissionSection(title: String, submission: MatchSubmissionModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(submission.words, id: \.word) { w in
                HStack {
                    Text(w.word.uppercased())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    Text("+\(w.points)")
                        .foregroundColor(.accentColor)
                }
            }
            Divider()
            HStack {
                Text("Total")
                Spacer()
                Text("\(submission.totalScore) pts").bold()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func loadSubmissions() async {
        guard let me = currentUserID, let opponent = opponentID else { return }
        mySubmission = try? await vm.fetchSubmission(matchID: match.id, userID: me)
        opponentSubmission = try? await vm.fetchSubmission(matchID: match.id, userID: opponent)
        isLoading = false
    }
}

// MARK: - Invite Friend
struct InviteFriendView: View {
    @EnvironmentObject var vm: MultiplayerViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0  // 0 = friends, 1 = search

    var body: some View {
        NavigationStack {
            Picker("Invite method", selection: $selectedTab) {
                Text("Friends").tag(0)
                Text("Search").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                friendsList
            } else {
                searchView
            }
        }
        .navigationTitle("Invite to Duel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var friendsList: some View {
        List(vm.friendsList) { friend in
            Button {
                guard let me = authVM.currentUserID else { return }
                Task {
                    try? await vm.sendInvite(from: me, to: friend.id)
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(friend.username)
                        .font(.body)
                }
            }
            .foregroundColor(.primary)
        }
    }

    private var searchView: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search username", text: $vm.searchUsername)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: vm.searchUsername) { _, q in
                        guard let me = authVM.currentUserID else { return }
                        Task { await vm.searchUsers(query: q, currentUserID: me) }
                    }
                if vm.isSearching { ProgressView() }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding()

            List(vm.searchResults) { user in
                Button {
                    guard let me = authVM.currentUserID else { return }
                    Task {
                        try? await vm.sendInvite(from: me, to: user.id)
                        dismiss()
                    }
                } label: {
                    Text(user.username)
                }
                .foregroundColor(.primary)
            }
        }
    }
}
