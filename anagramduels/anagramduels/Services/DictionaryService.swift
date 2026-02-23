import Foundation

/// Loads the Scrabble dictionary from the app bundle and provides
/// fast word-lookup and base-word selection.
///
/// Add your `dictionary.txt` file to the Xcode project (one word per line,
/// lower-case). The service is thread-safe after initialisation.
final class DictionaryService: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isLoaded = false

    // MARK: - Private Storage
    private var wordSet: Set<String> = []
    private var baseWordCandidates: [String] = []

    // MARK: - Init
    init() {
        load()
    }

    // MARK: - Public API

    /// Returns `true` when `word` exists in the dictionary.
    func isValid(_ word: String) -> Bool {
        wordSet.contains(word.lowercased())
    }

    /// Returns a random valid base word of exactly `AppConfig.Game.letterCount` letters.
    func randomBaseWord() -> String? {
        baseWordCandidates.randomElement()
    }

    // MARK: - Private

    private func load() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let fileName = AppConfig.Dictionary.fileName
            let ext      = AppConfig.Dictionary.fileExtension
            let minLen   = AppConfig.Dictionary.baseWordMinLength
            let maxLen   = AppConfig.Dictionary.baseWordMaxLength

            guard let url = Foundation.Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("[DictionaryService] ⚠️  \(fileName).\(ext) not found in bundle.")
                return
            }

            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                print("[DictionaryService] ⚠️  Failed to read dictionary file.")
                return
            }

            let lines = content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }

            let set        = Set(lines)
            let candidates = lines.filter { $0.count >= minLen && $0.count <= maxLen }

            await MainActor.run {
                self.wordSet            = set
                self.baseWordCandidates = candidates
                self.isLoaded           = true
                print("[DictionaryService] ✅ Loaded \(set.count) words, \(candidates.count) base-word candidates.")
            }
        }
    }
}
