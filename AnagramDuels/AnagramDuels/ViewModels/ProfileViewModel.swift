import Foundation
import Combine
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published private(set) var user: UserModel?
    @Published private(set) var globalStats: StatsModel?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isSavingSettings = false

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Load Profile

    func loadProfile(userID: UUID) async {
        isLoading = true
        do {
            let users: [UserModel] = try await supabase
                .from("users")
                .select()
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value
            user = users.first

            let stats: [StatsModel] = try await supabase
                .from("stats")
                .select()
                .eq("user_id", value: userID.uuidString)
                .eq("match_type", value: AppConfig.MatchType.multiplayer.rawValue)
                .is("friend_id", value: nil)
                .limit(1)
                .execute()
                .value
            globalStats = stats.first
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Settings

    func updateTheme(_ theme: AppConfig.ThemeMode, userID: UUID) async {
        isSavingSettings = true
        do {
            try await supabase
                .from("users")
                .update(["theme_mode": theme.rawValue])
                .eq("id", value: userID.uuidString)
                .execute()
            user?.themeMode = theme
        } catch {
            errorMessage = error.localizedDescription
        }
        isSavingSettings = false
    }

    func updateNotifications(enabled: Bool, userID: UUID) async {
        isSavingSettings = true
        do {
            try await supabase
                .from("users")
                .update(["notifications_enabled": enabled])
                .eq("id", value: userID.uuidString)
                .execute()
            user?.notificationsEnabled = enabled
            if enabled {
                _ = await NotificationService.shared.requestAuthorization()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSavingSettings = false
    }

    func updateUsername(_ newUsername: String, userID: UUID) async throws {
        guard newUsername.count >= 3 else {
            throw ProfileError.usernameTooShort
        }
        try await supabase
            .from("users")
            .update(["username": newUsername])
            .eq("id", value: userID.uuidString)
            .execute()
        user?.username = newUsername
    }
}

enum ProfileError: LocalizedError {
    case usernameTooShort

    var errorDescription: String? {
        switch self {
        case .usernameTooShort: return "Username must be at least 3 characters."
        }
    }
}
