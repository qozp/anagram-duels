import Foundation

/// Central configuration for all game constants.
/// Modify values here to tune gameplay — no magic numbers elsewhere in the codebase.
enum AppConfig {

    // MARK: - Game Timing
    /// Duration of each game round in seconds.
    static let gameDuration: Int = 60

    /// Countdown seconds shown before the game starts.
    static let countdownDuration: Int = 3

    // MARK: - Word Mechanics
    /// Length of the seed word (also the max hand size).
    static let seedWordLength: Int = 6

    /// Minimum number of letters required for a valid submission.
    static let minimumWordLength: Int = 2

    // MARK: - Scoring
    /// Points awarded per word length. Key = word length, Value = points.
    static let wordScores: [Int: Int] = [
        2: 100,
        3: 300,
        4: 600,
        5: 1000,
        6: 1500
    ]

    // MARK: - Star Thresholds (Singleplayer Levels)
    /// Minimum percentage of max score required to earn each star (1–3).
    /// Key = star number, Value = required fraction (0.0–1.0).
    static let starThresholds: [Int: Double] = [
        1: 0.30,
        2: 0.60,
        3: 0.85
    ]

    // MARK: - Level Progression
    /// Number of levels before a cumulative star checkpoint.
    static let levelsPerGroup: Int = 10

    // MARK: - Multiplayer
    /// Days before an unfinished match is automatically canceled.
    static let matchAutoCancelDays: Int = 7

    // MARK: - Daily Challenge
    /// How many days of daily challenges to generate ahead in the seed script.
    static let dailyChallengeGenerationDays: Int = 730

    // MARK: - Theme
    enum ThemeMode: String, CaseIterable, Codable {
        case system
        case light
        case dark

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    // MARK: - Match Status
    enum MatchStatus: String, Codable {
        case pending      = "pending"
        case inProgress   = "in_progress"
        case completed    = "completed"
        case canceled     = "canceled"
    }

    // MARK: - Friend Status
    enum FriendStatus: String, Codable {
        case pending  = "pending"
        case accepted = "accepted"
        case blocked  = "blocked"
    }

    // MARK: - Match Type (for stats)
    enum MatchType: String, Codable {
        case multiplayer = "multiplayer"
        case daily       = "daily"
        case level       = "level"
    }

    // MARK: - Helpers
    /// Returns the score for a given word length. Returns 0 if length is unsupported.
    static func score(forWordLength length: Int) -> Int {
        return wordScores[length] ?? 0
    }

    /// Returns the star count (0–3) for a given score fraction.
    static func stars(forFraction fraction: Double) -> Int {
        let sorted = starThresholds.sorted { $0.key > $1.key }
        for (star, threshold) in sorted {
            if fraction >= threshold { return star }
        }
        return 0
    }
}
