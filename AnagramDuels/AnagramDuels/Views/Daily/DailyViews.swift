import SwiftUI

// MARK: - Daily View
struct DailyView: View {
    @EnvironmentObject var vm: DailyViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading today's challenge…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.hasTodayChallenge {
                    dailyContent
                } else {
                    ContentUnavailableView(
                        "No challenge today",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Check back later.")
                    )
                }
            }
            .navigationTitle("Daily")
            .refreshable {
                if let id = authVM.currentUserID {
                    await vm.loadToday(userID: id)
                }
            }
        }
    }

    @ViewBuilder
    private var dailyContent: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Streak badge
                if vm.currentStreak > 0 {
                    Label("\(vm.currentStreak) day streak 🔥", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(20)
                }

                // Today's challenge card
                challengeCard

                // Leaderboard
                if let challenge = vm.todayChallenge {
                    LeaderboardView(
                        friendsEntries: vm.friendsLeaderboard,
                        globalEntries: vm.globalLeaderboard,
                        currentUserID: authVM.currentUserID
                    )
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var challengeCard: some View {
        if let challenge = vm.todayChallenge {
            VStack(spacing: 16) {
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(challenge.seedWord.uppercased())
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.accentColor)

                if vm.hasPlayedToday {
                    if let sub = vm.mySubmission {
                        VStack(spacing: 4) {
                            Text("Your Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sub.totalScore) pts")
                                .font(.title2.bold())
                            Text("\(sub.words.count) words found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                } else {
                    NavigationLink {
                        if let context = vm.dailyContext() {
                            GameBoardView(viewModel: GameViewModel(context: context))
                        }
                    } label: {
                        Text("Play Today's Challenge")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    let friendsEntries: [LeaderboardEntry]
    let globalEntries: [LeaderboardEntry]
    let currentUserID: UUID?

    @State private var selectedScope = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)

            Picker("Scope", selection: $selectedScope) {
                Text("Friends").tag(0)
                Text("Global").tag(1)
            }
            .pickerStyle(.segmented)

            let entries = selectedScope == 0 ? friendsEntries : globalEntries

            if entries.isEmpty {
                Text(selectedScope == 0 ? "No friends have played yet." : "No submissions yet.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.top, 4)
            } else {
                ForEach(entries.prefix(20)) { entry in
                    LeaderboardRow(entry: entry, isCurrentUser: entry.userID == currentUserID)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            Text("#\(entry.rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .leading)

            Text(isCurrentUser ? "You" : entry.username)
                .font(.system(size: 15, weight: isCurrentUser ? .bold : .regular))

            Spacer()

            Text("\(entry.totalScore) pts")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
        .background(isCurrentUser ? Color.accentColor.opacity(0.07) : Color.clear)
        .cornerRadius(8)
    }
}
