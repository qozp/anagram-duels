//
//  AnagramDuelsApp.swift
//  AnagramDuels
//
//  Created by Isaiah Pham on 2/23/26.
//

import SwiftUI

@main
struct AnagramDuelsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.resolvedColorScheme)
        }
    }
}
