import Foundation
import Combine
import Supabase

@MainActor
final class MultiplayerViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var matches: [MatchModel] = []
    @Published private(set) var friendsList: [UserModel] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchUsername = ""
    @Published var searchResults: [UserModel] = []
    @Published var isSearching = false

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Inbox

    func loadInbox(userID: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // Fetch all matches where this user is sender or receiver
            let senderMatches: [MatchModel] = try await supabase
                .from("matches")
                .select()
                .eq("invite_sender_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let receiverMatches: [MatchModel] = try await supabase
                .from("matches")
                .select()
                .eq("invite_receiver_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let all = (senderMatches + receiverMatches)
                .sorted { $0.createdAt > $1.createdAt }
                .reduce(into: [UUID: MatchModel]()) { $0[$1.id] = $1 }
                .values
                .sorted { $0.createdAt > $1.createdAt }

            matches = Array(all)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Friends

    func loadFriends(userID: UUID) async {
        do {
            let friendRecords: [FriendModel] = try await supabase
                .from("friends")
                .select()
                .eq("user_id", value: userID.uuidString)
                .eq("status", value: AppConfig.FriendStatus.accepted.rawValue)
                .execute()
                .value

            let friendIDs = friendRecords.map { $0.friendID.uuidString }
            guard !friendIDs.isEmpty else {
                friendsList = []
                return
            }

            let users: [UserModel] = try await supabase
                .from("users")
                .select()
                .in("id", values: friendIDs)
                .execute()
                .value
            friendsList = users
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Invite / New Match

    func sendInvite(from senderID: UUID, to receiverID: UUID) async throws {
        guard let seedWord = randomSeedWord() else {
            throw MatchError.noSeedWordAvailable
        }

        struct NewMatch: Encodable {
            let seed_word: String
            let status: String
            let invite_sender_id: String
            let invite_receiver_id: String
        }

        let record = NewMatch(
            seed_word: seedWord,
            status: AppConfig.MatchStatus.pending.rawValue,
            invite_sender_id: senderID.uuidString,
            invite_receiver_id: receiverID.uuidString
        )
        try await supabase.from("matches").insert(record).execute()
        await loadInbox(userID: senderID)
    }

    // MARK: - Username Search (for friend/invite lookup)

    func searchUsers(query: String, currentUserID: UUID) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            let results: [UserModel] = try await supabase
                .from("users")
                .select()
                .ilike("username", pattern: "%\(query)%")
                .neq("id", value: currentUserID.uuidString)
                .eq("guest_flag", value: false)
                .limit(10)
                .execute()
                .value
            searchResults = results
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    // MARK: - Friend Request

    func sendFriendRequest(from userID: UUID, to targetID: UUID) async throws {
        struct NewFriend: Encodable {
            let user_id: String
            let friend_id: String
            let status: String
        }

        let record = NewFriend(
            user_id: userID.uuidString,
            friend_id: targetID.uuidString,
            status: AppConfig.FriendStatus.pending.rawValue
        )
        try await supabase.from("friends").insert(record).execute()
    }

    func acceptFriendRequest(userID: UUID, fromFriendID: UUID) async throws {
        try await supabase
            .from("friends")
            .update(["status": AppConfig.FriendStatus.accepted.rawValue])
            .eq("user_id", value: fromFriendID.uuidString)
            .eq("friend_id", value: userID.uuidString)
            .execute()

        struct NewFriend: Encodable {
            let user_id: String
            let friend_id: String
            let status: String
        }

        let reverse = NewFriend(
            user_id: userID.uuidString,
            friend_id: fromFriendID.uuidString,
            status: AppConfig.FriendStatus.accepted.rawValue
        )
        try await supabase.from("friends").upsert(reverse).execute()
    }

    // MARK: - Submission Lookup

    func fetchSubmission(matchID: UUID, userID: UUID) async throws -> MatchSubmissionModel? {
        let results: [MatchSubmissionModel] = try await supabase
            .from("match_submissions")
            .select()
            .eq("match_id", value: matchID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func fetchAllSubmissions(matchID: UUID) async throws -> [MatchSubmissionModel] {
        return try await supabase
            .from("match_submissions")
            .select()
            .eq("match_id", value: matchID.uuidString)
            .execute()
            .value
    }

    // MARK: - Shareable Invite Link

    func shareableInviteLink(matchID: UUID) -> URL {
        // Deep link scheme: anagramduels://match/{matchID}
        return URL(string: "anagramduels://match/\(matchID.uuidString)")!
    }

    // MARK: - Helpers

    func hasSubmitted(match: MatchModel, userID: UUID) -> Bool {
        // Determined by fetching match_submissions; cached via inbox refresh
        // Simplified for now — full implementation uses submission cache
        return match.status == .completed
    }

    private func randomSeedWord() -> String? {
        // In a real implementation, pick a random 6-letter word from the word service
        // For MVP, this is handled by the backend or pre-selected
        return WordValidationService.shared.isLoaded ? nil : nil
        // TODO: implement random seed word selection from WordValidationService
    }
}

enum MatchError: LocalizedError {
    case noSeedWordAvailable

    var errorDescription: String? {
        switch self {
        case .noSeedWordAvailable: return "Unable to generate a new game right now."
        }
    }
}
