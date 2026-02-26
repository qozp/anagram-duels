import Foundation
import Combine
import Supabase

/// The core game engine. Owns all state for a single round.
/// Initialized fresh for each game session via a `GameContext`.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var handTiles: [LetterTile]         // 6 tiles, some may be placed
    @Published private(set) var wordSlots: [UUID?]              // 6 slots; nil = empty
    @Published private(set) var submittedWords: [ScoredWord] = []
    @Published private(set) var phase: GamePhase = .countdown(secondsLeft: AppConfig.countdownDuration)
    @Published private(set) var timeRemaining: Int = AppConfig.gameDuration
    @Published private(set) var feedbackMessage: String?        // transient word error / success
    @Published private(set) var totalScore: Int = 0
    @Published var isSubmittingResult = false
    @Published var resultSaveError: String?

    // MARK: - Computed
    var currentWordString: String {
        wordSlots
            .compactMap { id in handTiles.first(where: { $0.id == id })?.letter }
            .map(String.init)
            .joined()
    }

    var currentWordIsEmpty: Bool {
        wordSlots.allSatisfy { $0 == nil }
    }

    var submittedWordSet: Set<String> {
        Set(submittedWords.map { $0.word.lowercased() })
    }

    // MARK: - Private
    private let context: GameContext
    private let seedLetters: [Character]
    private let validator: WordValidationService
    private let scorer: GameScoringService.Type
    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?

    // MARK: - Init

    init(context: GameContext) {
        self.context = context
        self.validator = WordValidationService.shared
        self.scorer = GameScoringService.self

        let seed = context.seedWord.uppercased()
        precondition(
            seed.count == AppConfig.seedWordLength,
            "Seed word must be exactly \(AppConfig.seedWordLength) characters."
        )

        self.seedLetters = Array(seed.lowercased())
        self.handTiles = seed.enumerated().map { LetterTile(letter: $0.element, handIndex: $0.offset) }
        self.wordSlots = Array(repeating: nil, count: AppConfig.seedWordLength)
    }

    deinit {
        timerTask?.cancel()
        feedbackTask?.cancel()
    }

    // MARK: - Lifecycle

    func startGame() {
        guard case .countdown = phase else { return }
        startCountdown()
    }

    private func startCountdown() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            var remaining = AppConfig.countdownDuration
            while remaining > 0 {
                self.phase = .countdown(secondsLeft: remaining)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                remaining -= 1
            }
            self.beginRound()
        }
    }

    private func beginRound() {
        phase = .playing
        timeRemaining = AppConfig.gameDuration
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while self.timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.timeRemaining -= 1
            }
            self.endGame()
        }
    }

    func endGame() {
        timerTask?.cancel()
        phase = .results
        Task { await saveResult() }
    }

    // MARK: - Tile Interaction

    /// Taps a hand tile: places it in the next available word slot (if not already placed).
    func tapHandTile(id: UUID) {
        guard phase == .playing else { return }
        guard let tileIndex = handTiles.firstIndex(where: { $0.id == id }) else { return }
        guard !handTiles[tileIndex].isPlaced else { return }

        guard let emptySlot = wordSlots.firstIndex(where: { $0 == nil }) else { return }

        handTiles[tileIndex].isPlaced = true
        wordSlots[emptySlot] = id
    }

    /// Taps a word slot tile: returns it to its original hand position.
    func tapWordSlot(at slotIndex: Int) {
        guard phase == .playing else { return }
        guard let tileID = wordSlots[slotIndex] else { return }
        guard let tileIndex = handTiles.firstIndex(where: { $0.id == tileID }) else { return }

        wordSlots[slotIndex] = nil
        handTiles[tileIndex].isPlaced = false
    }

    /// Clears all word slots, returning every tile to its original hand position.
    func clearWord() {
        guard phase == .playing else { return }
        for i in wordSlots.indices {
            if let tileID = wordSlots[i],
               let tileIndex = handTiles.firstIndex(where: { $0.id == tileID }) {
                handTiles[tileIndex].isPlaced = false
            }
            wordSlots[i] = nil
        }
    }

    // MARK: - Word Submission

    func submitCurrentWord() {
        guard phase == .playing else { return }
        let word = currentWordString
        guard !word.isEmpty else { return }

        let result = validator.validate(
            candidate: word,
            seedLetters: seedLetters,
            alreadySubmitted: submittedWordSet
        )

        switch result {
        case .success:
            let points = scorer.score(for: word)
            let scored = ScoredWord(word: word.lowercased(), points: points)
            submittedWords.append(scored)
            totalScore += points
            showFeedback("+\(points)pts")
            clearWord()

        case .failure(let error):
            showFeedback(error.errorDescription ?? "Invalid word")
        }
    }

    // MARK: - Feedback

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        feedbackTask?.cancel()
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if Task.isCancelled { return }
            self?.feedbackMessage = nil
        }
    }

    // MARK: - Result Saving

    private func saveResult() async {
        guard context.canSaveResult else { return }

        isSubmittingResult = true
        resultSaveError = nil

        let result = GameResult(
            context: context,
            scoredWords: submittedWords,
            totalScore: totalScore,
            completedAt: Date()
        )

        do {
            switch context {
            case .multiplayer(let match):
                try await saveMultiplayerSubmission(result: result, match: match)
            case .daily(let challenge):
                try await saveDailySubmission(result: result, challenge: challenge)
            case .level(let level):
                try await saveLevelResult(result: result, level: level)
            case .practice:
                break
            }
        } catch {
            resultSaveError = "Failed to save result: \(error.localizedDescription)"
        }

        isSubmittingResult = false
    }

    private func saveMultiplayerSubmission(result: GameResult, match: MatchModel) async throws {
        guard let userID = await AuthService.shared.currentUserID else {
            throw AuthError.noActiveSession
        }

        struct NewSubmission: Encodable {
            let match_id: String
            let user_id: String
            let words: [SubmittedWord]
            let total_score: Int
        }

        let record = NewSubmission(
            match_id: match.id.uuidString,
            user_id: userID.uuidString,
            words: result.scoredWords.map { SubmittedWord(word: $0.word, points: $0.points) },
            total_score: result.totalScore
        )

        try await SupabaseService.shared.client
            .from("match_submissions")
            .insert(record)
            .execute()

        // Check if opponent has also submitted; if so, mark match as completed
        let submissions: [MatchSubmissionModel] = try await SupabaseService.shared.client
            .from("match_submissions")
            .select()
            .eq("match_id", value: match.id.uuidString)
            .execute()
            .value

        struct MatchStatusUpdate: Encodable {
            let status: String
            var completed_at: String?
        }

        if submissions.count >= 2 {
            let update = MatchStatusUpdate(
                status: AppConfig.MatchStatus.completed.rawValue,
                completed_at: ISO8601DateFormatter().string(from: Date())
            )
            try await SupabaseService.shared.client
                .from("matches")
                .update(update)
                .eq("id", value: match.id.uuidString)
                .execute()
        } else {
            let update = MatchStatusUpdate(status: AppConfig.MatchStatus.inProgress.rawValue)
            try await SupabaseService.shared.client
                .from("matches")
                .update(update)
                .eq("id", value: match.id.uuidString)
                .execute()
        }
    }

    private func saveDailySubmission(result: GameResult, challenge: DailyChallengeModel) async throws {
        guard let userID = await AuthService.shared.currentUserID else {
            throw AuthError.noActiveSession
        }

        struct NewDailySubmission: Encodable {
            let daily_challenge_id: String
            let user_id: String
            let words: [SubmittedWord]
            let total_score: Int
        }

        let record = NewDailySubmission(
            daily_challenge_id: challenge.id.uuidString,
            user_id: userID.uuidString,
            words: result.scoredWords.map { SubmittedWord(word: $0.word, points: $0.points) },
            total_score: result.totalScore
        )

        try await SupabaseService.shared.client
            .from("daily_challenge_submissions")
            .insert(record)
            .execute()
    }

    private func saveLevelResult(result: GameResult, level: LevelModel) async throws {
        // Level results are stored locally or in a user_level_progress table (future)
        // For MVP, store in stats table
        _ = result
    }
}
