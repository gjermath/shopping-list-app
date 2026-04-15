import SwiftUI

struct ContentView: View {
    @StateObject private var listService = ListService()
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()

            TabView {
                ListsTabView()
                    .tabItem {
                        Label("Lists", systemImage: "list.bullet")
                    }

                ActivityTabView()
                    .tabItem {
                        Label("Activity", systemImage: "clock")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .tint(Theme.primaryGreen)
        }
        .environmentObject(listService)
        .environmentObject(networkMonitor)
        .onAppear { listService.startListening() }
        .onDisappear { listService.stopListening() }
    }
}
