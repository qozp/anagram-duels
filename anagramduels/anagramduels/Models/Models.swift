import Foundation

// MARK: - AppUser
/// Mirrors the `profiles` table in Supabase.
struct AppUser: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var avatarURL: String?
    var wins: Int
    var losses: Int
    var totalWordsFound: Int

    var winRate: Double {
        let played = wins + losses
        guard played > 0 else { return 0 }
        return Double(wins) / Double(played)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarURL        = "avatar_url"
        case wins
        case losses
        case totalWordsFound  = "total_words_found"
    }
}

// MARK: - Match
/// Mirrors the `matches` table in Supabase.
struct Match: Codable, Identifiable {
    let id: UUID
    let playerOneID: UUID
    let playerTwoID: UUID?
    var status: MatchStatus
    var mode: AppConfig.RoundMode
    var baseWord: String
    var letters: [String]          // shuffled letter set shown to both players
    var playerOneScore: Int
    var playerTwoScore: Int
    var winnerID: UUID?
    let createdAt: Date

    enum MatchStatus: String, Codable {
        case waiting    = "waiting"
        case active     = "active"
        case completed  = "completed"
        case abandoned  = "abandoned"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case playerOneID    = "player_one_id"
        case playerTwoID    = "player_two_id"
        case status
        case mode
        case baseWord       = "base_word"
        case letters
        case playerOneScore = "player_one_score"
        case playerTwoScore = "player_two_score"
        case winnerID       = "winner_id"
        case createdAt      = "created_at"
    }
}

// MARK: - SubmittedWord
/// A word submitted by a player during a match.
struct SubmittedWord: Codable, Identifiable, Equatable {
    let id: UUID
    let matchID: UUID
    let playerID: UUID
    let word: String
    let points: Int
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case matchID      = "match_id"
        case playerID     = "player_id"
        case word
        case points
        case submittedAt  = "submitted_at"
    }
}

// MARK: - FriendInvite
struct FriendInvite: Codable, Identifiable {
    let id: UUID
    let fromPlayerID: UUID
    let toPlayerID: UUID
    var status: InviteStatus
    let createdAt: Date

    enum InviteStatus: String, Codable {
        case pending   = "pending"
        case accepted  = "accepted"
        case declined  = "declined"
        case expired   = "expired"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fromPlayerID = "from_player_id"
        case toPlayerID   = "to_player_id"
        case status
        case createdAt    = "created_at"
    }
}

// MARK: - WordValidationResult
enum WordValidationResult: Equatable {
    case valid(points: Int)
    case invalid(reason: InvalidReason)

    enum InvalidReason: String {
        case notInDictionary   = "Not a valid word"
        case lettersUnavailable = "Letters not available"
        case alreadySubmitted  = "Already submitted"
        case tooShort          = "Too short"
    }
}
