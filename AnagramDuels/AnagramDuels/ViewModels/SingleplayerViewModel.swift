import Foundation
import Combine
import Supabase

@MainActor
final class SingleplayerViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var levels: [LevelModel] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Current practice seed (set when starting practice mode)
    @Published private(set) var practiceSeedWord: String = ""

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Levels

    func loadLevels() async {
        isLoading = true
        do {
            levels = try await supabase
                .from("levels")
                .select()
                .order("level_number", ascending: true)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func level(number: Int) -> LevelModel? {
        levels.first { $0.levelNumber == number }
    }

    /// Groups levels into sets of `AppConfig.levelsPerGroup` for the world/chapter UI.
    var levelGroups: [[LevelModel]] {
        stride(from: 0, to: levels.count, by: AppConfig.levelsPerGroup).map { start in
            let end = min(start + AppConfig.levelsPerGroup, levels.count)
            return Array(levels[start..<end])
        }
    }

    // MARK: - Practice Mode

    /// Picks a random 6-letter word from the loaded dictionary and assigns it as the practice seed.
    func preparePracticeGame() {
        practiceSeedWord = randomSixLetterWord() ?? "GARDEN"
    }

    func practiceContext() -> GameContext {
        .practice(seedWord: practiceSeedWord)
    }

    func levelContext(_ level: LevelModel) -> GameContext {
        .level(level)
    }

    // MARK: - Helpers

    private func randomSixLetterWord() -> String? {
        WordValidationService.shared.randomWord(ofLength: AppConfig.seedWordLength)
    }
}
