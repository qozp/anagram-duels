import Foundation

// MARK: - User
struct UserModel: Codable, Identifiable {
    let id: UUID
    var username: String
    let appleID: String?
    let guestFlag: Bool
    var themeMode: AppConfig.ThemeMode
    var notificationsEnabled: Bool
    var pushToken: String?
    var cosmeticConfig: CosmeticConfig?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case appleID              = "apple_id"
        case guestFlag            = "guest_flag"
        case themeMode            = "theme_mode"
        case notificationsEnabled = "notifications_enabled"
        case pushToken            = "push_token"
        case cosmeticConfig       = "cosmetic_config"
        case createdAt            = "created_at"
        case updatedAt            = "updated_at"
    }
}

struct CosmeticConfig: Codable {
    // Reserved for future cosmetic customization
    var tileColor: String?
    var backgroundTheme: String?
}

// MARK: - Friend
struct FriendModel: Codable {
    let userID: UUID
    let friendID: UUID
    let status: AppConfig.FriendStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userID    = "user_id"
        case friendID  = "friend_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Match
struct MatchModel: Codable, Identifiable {
    let id: UUID
    let seedWord: String
    var status: AppConfig.MatchStatus
    let inviteSenderID: UUID
    let inviteReceiverID: UUID
    let createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var canceledAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case seedWord         = "seed_word"
        case status
        case inviteSenderID   = "invite_sender_id"
        case inviteReceiverID = "invite_receiver_id"
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
        case completedAt      = "completed_at"
        case canceledAt       = "canceled_at"
    }
}

// MARK: - Match Submission
struct MatchSubmissionModel: Codable, Identifiable {
    let id: UUID
    let matchID: UUID
    let userID: UUID
    let words: [SubmittedWord]
    let totalScore: Int
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case matchID     = "match_id"
        case userID      = "user_id"
        case words
        case totalScore  = "total_score"
        case submittedAt = "submitted_at"
    }
}

struct SubmittedWord: Codable {
    let word: String
    let points: Int
}

// MARK: - Level
struct LevelModel: Codable, Identifiable {
    let id: UUID
    let levelNumber: Int
    let seedWord: String
    let maxScore: Int
    let starThresholds: LevelStarThresholds
    let themeName: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case levelNumber   = "level_number"
        case seedWord      = "seed_word"
        case maxScore      = "max_score"
        case starThresholds = "star_thresholds"
        case themeName     = "theme_name"
        case createdAt     = "created_at"
    }
}

struct LevelStarThresholds: Codable {
    let one: Double
    let two: Double
    let three: Double

    enum CodingKeys: String, CodingKey {
        case one   = "1"
        case two   = "2"
        case three = "3"
    }
}

// MARK: - Daily Challenge
struct DailyChallengeModel: Codable, Identifiable {
    let id: UUID
    let challengeDate: Date
    let seedWord: String
    let maxScore: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case challengeDate = "challenge_date"
        case seedWord      = "seed_word"
        case maxScore      = "max_score"
        case createdAt     = "created_at"
    }
}

// MARK: - Daily Challenge Submission
struct DailyChallengeSubmissionModel: Codable, Identifiable {
    let id: UUID
    let dailyChallengeID: UUID
    let userID: UUID
    let words: [SubmittedWord]
    let totalScore: Int
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case dailyChallengeID = "daily_challenge_id"
        case userID           = "user_id"
        case words
        case totalScore       = "total_score"
        case submittedAt      = "submitted_at"
    }
}

// MARK: - Stats
struct StatsModel: Codable, Identifiable {
    let id: UUID
    let userID: UUID
    let friendID: UUID?
    let matchType: AppConfig.MatchType
    var totalGames: Int
    var wins: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID         = "user_id"
        case friendID       = "friend_id"
        case matchType      = "match_type"
        case totalGames     = "total_games"
        case wins
        case currentStreak  = "current_streak"
        case longestStreak  = "longest_streak"
        case lastUpdated    = "last_updated"
    }

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames)
    }

    var losses: Int { totalGames - wins }
}

// MARK: - Leaderboard Entry (derived, not a table)
struct LeaderboardEntry: Identifiable {
    let id: UUID
    let userID: UUID
    let username: String
    let totalScore: Int
    let rank: Int
    let submittedAt: Date
}
