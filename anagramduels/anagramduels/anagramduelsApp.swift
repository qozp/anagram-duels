//
//  anagramduelsApp.swift
//  anagramduels
//
//  Created by Isaiah Pham on 2/23/26.
//

import SwiftUI

@main
struct anagramduelsApp: App {

    @StateObject private var router = AppRouter()
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(authService)
        }
    }
}
