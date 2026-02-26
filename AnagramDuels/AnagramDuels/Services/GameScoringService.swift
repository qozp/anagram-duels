import Foundation

/// Pure scoring logic — no state, no side effects.
/// All scoring decisions route through here so the table only needs to change in AppConfig.
enum GameScoringService {

    /// Returns the point value for a word of the given length.
    static func score(forWordLength length: Int) -> Int {
        return AppConfig.score(forWordLength: length)
    }

    /// Returns the point value for a specific word string.
    static func score(for word: String) -> Int {
        return score(forWordLength: word.count)
    }

    /// Sums the scores of a collection of scored words.
    static func total(for words: [ScoredWord]) -> Int {
        return words.reduce(0) { $0 + $1.points }
    }

    /// Determines how many stars (0–3) a player earned.
    /// - Parameters:
    ///   - score: The player's achieved score.
    ///   - maxScore: The theoretically maximum score for the level.
    static func stars(forScore score: Int, maxScore: Int) -> Int {
        guard maxScore > 0 else { return 0 }
        let fraction = Double(score) / Double(maxScore)
        return AppConfig.stars(forFraction: fraction)
    }

    /// Returns true if the player earns the 4th star (found the exact seed word).
    /// - Parameters:
    ///   - submittedWords: Words the player found.
    ///   - seedWord: The level's seed word (for themed levels) or any valid 6-letter word (default).
    ///   - isThemed: If true, the player must find the exact seed word for the 4th star.
    static func earnsFourthStar(
        submittedWords: [ScoredWord],
        seedWord: String,
        isThemed: Bool
    ) -> Bool {
        let submitted = Set(submittedWords.map { $0.word.lowercased() })
        if isThemed {
            return submitted.contains(seedWord.lowercased())
        } else {
            return submittedWords.contains { $0.word.count == AppConfig.seedWordLength }
        }
    }
}
