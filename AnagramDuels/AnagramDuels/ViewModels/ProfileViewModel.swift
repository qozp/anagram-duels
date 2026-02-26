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

    // MARK: - Profile Editing

    func updateDisplayName(_ newName: String, userID: UUID) async throws {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard trimmed.count <= 40 else { throw ProfileError.displayNameTooLong }
        // Empty string clears the display name
        let value: String? = trimmed.isEmpty ? nil : trimmed
        try await supabase
            .from("users")
            .update(["display_name": value])
            .eq("id", value: userID.uuidString)
            .execute()
        user?.displayName = value
    }

    func updateUsername(_ newUsername: String, userID: UUID) async throws {
        let trimmed = newUsername.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3  else { throw ProfileError.usernameTooShort }
        guard trimmed.count <= 20 else { throw ProfileError.usernameTooLong }
        guard trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            throw ProfileError.usernameInvalidCharacters
        }
        try await supabase
            .from("users")
            .update(["username": trimmed])
            .eq("id", value: userID.uuidString)
            .execute()
        user?.username = trimmed
    }
}

// MARK: - Errors
enum ProfileError: LocalizedError {
    case usernameTooShort
    case usernameTooLong
    case usernameInvalidCharacters
    case displayNameTooLong

    var errorDescription: String? {
        switch self {
        case .usernameTooShort:          return "Username must be at least 3 characters."
        case .usernameTooLong:           return "Username must be 20 characters or fewer."
        case .usernameInvalidCharacters: return "Username can only contain letters, numbers, and underscores."
        case .displayNameTooLong:        return "Display name must be 40 characters or fewer."
        }
    }
}
