import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var singleplayerVM = SingleplayerViewModel()
    @StateObject private var multiplayerVM  = MultiplayerViewModel()
    @StateObject private var dailyVM        = DailyViewModel()
    @StateObject private var profileVM      = ProfileViewModel()

    var body: some View {
        TabView {
            SingleplayerHomeView()
                .environmentObject(singleplayerVM)
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            MultiplayerInboxView()
                .environmentObject(multiplayerVM)
                .tabItem { Label("Multiplayer", systemImage: "person.2.fill") }

            DailyView()
                .environmentObject(dailyVM)
                .tabItem { Label("Daily", systemImage: "calendar") }

            ProfileView()
                .environmentObject(profileVM)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.accentColor)
        .onAppear { loadInitialData() }
    }

    private func loadInitialData() {
        guard let userID = authVM.currentUserID else { return }
        Task {
            await dailyVM.loadToday(userID: userID)
            await profileVM.loadProfile(userID: userID)
            await multiplayerVM.loadInbox(userID: userID)
            await multiplayerVM.loadFriends(userID: userID)
        }
    }
}
