import Foundation
import UserNotifications
import UIKit
import Supabase

/// Manages push notification registration and token storage.
/// For MVP, this handles APNs setup. The actual sending happens via Supabase Edge Functions.
final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    // MARK: - Registration

    /// Requests permission and registers for remote notifications.
    /// Should be called after the user is authenticated and has enabled notifications in settings.
    @MainActor
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    /// Checks current authorization status without prompting.
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Token Storage

    /// Converts APNs device token Data to a hex string and stores it in the database.
    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            await storePushToken(token)
        }
    }

    private func storePushToken(_ token: String) async {
        guard let userID = await AuthService.shared.currentUserID else { return }
        do {
            try await SupabaseService.shared.client
                .from("users")
                .update(["push_token": token])
                .eq("id", value: userID)
                .execute()
        } catch {
            // Non-fatal: notifications will just not work until next registration
            print("[NotificationService] Failed to store push token: \(error)")
        }
    }

    // MARK: - Local Notifications (MVP Placeholder)

    /// Schedules a local notification (used as fallback when app is foregrounded).
    func scheduleMatchReadyNotification(opponentUsername: String) {
        let content = UNMutableNotificationContent()
        content.title = "Your move!"
        content.body = "\(opponentUsername) has submitted their words. It's your turn!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
