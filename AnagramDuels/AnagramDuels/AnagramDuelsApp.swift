import SwiftUI

@main
struct AnagramDuelsApp: App {

    @StateObject private var authVM = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .preferredColorScheme(colorScheme(for: authVM))
                .task {
                    // Load the word dictionary on first launch (background)
                    await WordValidationService.shared.loadDictionary()
                }
        }
    }

    private func colorScheme(for auth: AuthViewModel) -> ColorScheme? {
        switch auth.state {
        case .authenticated(let user):
            switch user.themeMode {
            case .light:  return .light
            case .dark:   return .dark
            case .system: return nil
            }
        default:
            return nil
        }
    }
}

// MARK: - App Delegate (APNs)
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }
}
