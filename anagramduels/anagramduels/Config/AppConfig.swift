import Foundation
import CoreGraphics

/// Central configuration for Anagram Duels.
/// All tunable values live here. No magic numbers elsewhere in the codebase.
enum AppConfig {

    // MARK: - Bundle
    enum Bundle {
        static let identifier = "com.stewgames.anagramduels"
    }

    // MARK: - Game Rules
    enum Game {
        /// Number of letters in the shared letter set each round.
        static let letterCount: Int = 6

        /// Shortest word that will be accepted.
        static let minWordLength: Int = 1

        /// Default round duration in seconds (time-based mode).
        static let defaultRoundDuration: TimeInterval = 120

        /// Default target score (target-score mode).
        static let defaultTargetScore: Int = 3000

        /// Default target word count (target-word-count mode).
        static let defaultTargetWordCount: Int = 10

        /// Points awarded indexed by word length.
        /// Key = number of letters, Value = points.
        static let scoringTable: [Int: Int] = [
            2: 100,
            3: 200,
            4: 500,
            5: 1000,
            6: 2000,
        ]

        /// Returns points for a given word, or 0 if length is unrecognised.
        static func points(for word: String) -> Int {
            scoringTable[word.count] ?? 0
        }
    }

    // MARK: - Round Modes
    enum RoundMode: String, CaseIterable, Codable, Identifiable {
        case timeBased       = "time_based"
        case targetScore     = "target_score"
        case targetWordCount = "target_word_count"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .timeBased:       return "Time Limit"
            case .targetScore:     return "Target Score"
            case .targetWordCount: return "Word Count"
            }
        }
    }

    // MARK: - Dictionary
    enum Dictionary {
        static let fileName: String      = "dictionary"
        static let fileExtension: String = "txt"
        /// Minimum length a word must have to be eligible as a round base word.
        static let baseWordMinLength: Int = Game.letterCount
        static let baseWordMaxLength: Int = Game.letterCount
    }

    // MARK: - Networking / Realtime
    enum Network {
        static let realtimeHeartbeatInterval: TimeInterval = 30
        /// How long to wait before declaring a disconnect.
        static let disconnectTimeout: TimeInterval = 10
    }

    // MARK: - UI / Layout
    enum UI {
        static let animationDuration: TimeInterval = 0.25
        static let feedbackBannerDuration: TimeInterval = 1.2
        static let cornerRadius: CGFloat        = 14
        static let letterTileSize: CGFloat      = 54
        static let letterTileSpacing: CGFloat   = 8
        static let primaryButtonHeight: CGFloat = 54
    }

    // MARK: - Haptics
    enum Haptics {
        static let defaultEnabled: Bool = true
    }

    // MARK: - Leaderboard
    enum Leaderboard {
        static let pageSize: Int = 50
    }
}
