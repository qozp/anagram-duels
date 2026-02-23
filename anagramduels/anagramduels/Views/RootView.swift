import SwiftUI

struct RootView: View {
    @State private var showWelcome = true
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Group {
                    if showWelcome {
                        WelcomeView(onContinue: {
                            showWelcome = false
                        })
                    } else {
                        switch authManager.authState {
                        case .unauthenticated:
                            WelcomeView() // optional: can show again if unauthenticated
                        case .guest, .authenticated:
                            MainTabView()
                        }
                    }
                }
        .animation(.easeInOut(duration: 0.3), value: authManager.authState)
        .observingTheme()
    }
}
