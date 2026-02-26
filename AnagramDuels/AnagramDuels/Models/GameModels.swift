import Foundation

// MARK: - Letter Tile
/// A single letter tile in the player's hand.
struct LetterTile: Identifiable, Equatable {
    let id: UUID
    let letter: Character
    /// Fixed position (0..<seedWordLength) in the hand row.
    let handIndex: Int
    /// Whether this tile is currently placed in a word slot.
    var isPlaced: Bool = false

    init(letter: Character, handIndex: Int) {
        self.id = UUID()
        self.letter = letter
        self.handIndex = handIndex
    }
}

// MARK: - Scored Word
/// A validated word and its earned points for the current round.
struct ScoredWord: Identifiable, Equatable {
    let id: UUID
    let word: String
    let points: Int

    init(word: String, points: Int) {
        self.id = UUID()
        self.word = word
        self.points = points
    }
}

// MARK: - Game Phase
enum GamePhase: Equatable {
    case countdown(secondsLeft: Int)
    case playing
    case results
}

// MARK: - Game Context
/// Determines what kind of session is being played and how results are saved.
enum GameContext {
    /// Free-play practice round. Carries its own seed word so GameViewModel
    /// needs no special-casing — just pass `.practice(seedWord: "GARDEN")`.
    case practice(seedWord: String)
    case level(LevelModel)
    case multiplayer(MatchModel)
    case daily(DailyChallengeModel)

    var seedWord: String {
        switch self {
        case .practice(let word):
            return word
        case .level(let level):
            return level.seedWord
        case .multiplayer(let match):
            return match.seedWord
        case .daily(let challenge):
            return challenge.seedWord
        }
    }

    var isTimed: Bool { true }

    var canSaveResult: Bool {
        switch self {
        case .practice: return false
        default:        return true
        }
    }
}

// MARK: - Word Submission Error
enum WordSubmissionError: LocalizedError, Equatable {
    case tooShort(minimum: Int)
    case notInDictionary
    case cannotBeFormedFromLetters
    case alreadySubmitted

    var errorDescription: String? {
        switch self {
        case .tooShort(let min):
            return "Words must be at least \(min) letters."
        case .notInDictionary:
            return "Not a valid word."
        case .cannotBeFormedFromLetters:
            return "Can't be made from these letters."
        case .alreadySubmitted:
            return "Already submitted this word."
        }
    }
}

// MARK: - Game Result (passed to save services)
struct GameResult {
    let context: GameContext
    let scoredWords: [ScoredWord]
    let totalScore: Int
    let completedAt: Date
}
