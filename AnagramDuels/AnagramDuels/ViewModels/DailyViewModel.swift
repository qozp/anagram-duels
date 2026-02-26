import Foundation
import Combine
import Supabase

@MainActor
final class DailyViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var todayChallenge: DailyChallengeModel?
    @Published private(set) var mySubmission: DailyChallengeSubmissionModel?
    @Published private(set) var friendsLeaderboard: [LeaderboardEntry] = []
    @Published private(set) var globalLeaderboard: [LeaderboardEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var currentStreak: Int = 0
    @Published var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    var hasPlayedToday: Bool { mySubmission != nil }
    var hasTodayChallenge: Bool { todayChallenge != nil }

    // MARK: - Load Today

    func loadToday(userID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let today = ISO8601DateFormatter.dateOnly(from: Date())

            // Fetch today's challenge
            let challenges: [DailyChallengeModel] = try await supabase
                .from("daily_challenges")
                .select()
                .eq("challenge_date", value: today)
                .limit(1)
                .execute()
                .value

            todayChallenge = challenges.first

            guard let challenge = todayChallenge else {
                isLoading = false
                return
            }

            // Check if user already submitted
            let submissions: [DailyChallengeSubmissionModel] = try await supabase
                .from("daily_challenge_submissions")
                .select()
                .eq("daily_challenge_id", value: challenge.id.uuidString)
                .eq("user_id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value

            mySubmission = submissions.first

            await loadLeaderboard(challengeID: challenge.id, userID: userID)
            await loadStreak(userID: userID)

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Leaderboard

    func loadLeaderboard(challengeID: UUID, userID: UUID) async {
        do {
            // Fetch all submissions for this challenge
            let allSubmissions: [DailyChallengeSubmissionModel] = try await supabase
                .from("daily_challenge_submissions")
                .select()
                .eq("daily_challenge_id", value: challengeID.uuidString)
                .order("total_score", ascending: false)
                .order("submitted_at", ascending: true)
                .limit(100)
                .execute()
                .value

            // Fetch usernames
            let userIDs = allSubmissions.map { $0.userID.uuidString }
            guard !userIDs.isEmpty else { return }

            let users: [UserModel] = try await supabase
                .from("users")
                .select()
                .in("id", values: userIDs)
                .execute()
                .value

            let usernameMap = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.username) })

            // Fetch friend IDs for friends leaderboard
            let friends: [FriendModel] = try await supabase
                .from("friends")
                .select()
                .eq("user_id", value: userID.uuidString)
                .eq("status", value: AppConfig.FriendStatus.accepted.rawValue)
                .execute()
                .value

            let friendIDs = Set(friends.map { $0.friendID }).union([userID])

            let entries = allSubmissions.enumerated().map { rank, sub -> LeaderboardEntry in
                LeaderboardEntry(
                    id: sub.id,
                    userID: sub.userID,
                    username: usernameMap[sub.userID] ?? "Unknown",
                    totalScore: sub.totalScore,
                    rank: rank + 1,
                    submittedAt: sub.submittedAt
                )
            }

            globalLeaderboard = entries
            friendsLeaderboard = entries.filter { friendIDs.contains($0.userID) }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Streak

    func loadStreak(userID: UUID) async {
        do {
            let stats: [StatsModel] = try await supabase
                .from("stats")
                .select()
                .eq("user_id", value: userID.uuidString)
                .eq("match_type", value: AppConfig.MatchType.daily.rawValue)
                .is("friend_id", value: nil)
                .limit(1)
                .execute()
                .value
            currentStreak = stats.first?.currentStreak ?? 0
        } catch {
            currentStreak = 0
        }
    }

    // MARK: - Context Factory

    func dailyContext() -> GameContext? {
        guard let challenge = todayChallenge else { return nil }
        return .daily(challenge)
    }
}

// MARK: - Date Helpers
private extension ISO8601DateFormatter {
    static func dateOnly(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
