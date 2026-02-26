import Foundation

/// Loads the bundled word list and provides fast word validation.
/// The dictionary is loaded once at app launch into a Set for O(1) lookups.
final class WordValidationService {

    static let shared = WordValidationService()

    private(set) var isLoaded = false
    private var wordSet: Set<String> = []

    private init() {}

    // MARK: - Loading

    /// Loads words.txt from the app bundle in a background task.
    /// Should be called once at app startup.
    func loadDictionary() async {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "words", withExtension: "txt") else {
            assertionFailure("words.txt not found in app bundle. Add it to the Xcode target.")
            return
        }

        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let words = contents
                .components(separatedBy: .newlines)
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            wordSet = Set(words)
            isLoaded = true
        } catch {
            assertionFailure("Failed to load words.txt: \(error)")
        }
    }

    // MARK: - Validation

    /// Returns true if `word` exists in the dictionary.
    func isValidWord(_ word: String) -> Bool {
        return wordSet.contains(word.lowercased())
    }

    /// Validates a candidate word against all submission rules.
    /// - Parameters:
    ///   - candidate: The word the player is submitting.
    ///   - seedLetters: The current hand letters (with repetition).
    ///   - alreadySubmitted: Words already scored this round.
    /// - Returns: `.success` or a `WordSubmissionError`.
    func validate(
        candidate: String,
        seedLetters: [Character],
        alreadySubmitted: Set<String>
    ) -> Result<Void, WordSubmissionError> {
        let normalized = candidate.lowercased()

        if normalized.count < AppConfig.minimumWordLength {
            return .failure(.tooShort(minimum: AppConfig.minimumWordLength))
        }

        if alreadySubmitted.contains(normalized) {
            return .failure(.alreadySubmitted)
        }

        if !canForm(word: normalized, from: seedLetters) {
            return .failure(.cannotBeFormedFromLetters)
        }

        if !isValidWord(normalized) {
            return .failure(.notInDictionary)
        }

        return .success(())
    }

    /// Determines whether `word` can be constructed from the available `letters` (respecting duplicates).
    func canForm(word: String, from letters: [Character]) -> Bool {
        var available = letterFrequency(letters)
        for char in word.lowercased() {
            let count = available[char, default: 0]
            guard count > 0 else { return false }
            available[char] = count - 1
        }
        return true
    }

    // MARK: - Random Word Selection

    /// Returns a random word of exactly `length` letters from the loaded dictionary.
    /// Returns `nil` if the dictionary isn't loaded yet.
    func randomWord(ofLength length: Int) -> String? {
        guard isLoaded else { return nil }
        // Filter lazily and reservoir-sample so we never build a full filtered array on every call
        var result: String?
        var count = 0
        for word in wordSet where word.count == length && word.allSatisfy(\.isLetter) {
            count += 1
            if Int.random(in: 0..<count) == 0 {
                result = word
            }
        }
        return result
    }

    // MARK: - Max Score Computation

    /// Finds all valid words formable from `seedLetters` and returns their total max score.
    func computeMaxScore(for seedWord: String) -> Int {
        guard isLoaded else { return 0 }
        let letters = Array(seedWord.lowercased())
        var total = 0
        for word in wordSet {
            let len = word.count
            guard len >= AppConfig.minimumWordLength, len <= AppConfig.seedWordLength else { continue }
            if canForm(word: word, from: letters) {
                total += AppConfig.score(forWordLength: len)
            }
        }
        return total
    }

    // MARK: - Helpers

    private func letterFrequency(_ letters: [Character]) -> [Character: Int] {
        var freq: [Character: Int] = [:]
        for c in letters { freq[c, default: 0] += 1 }
        return freq
    }
}
