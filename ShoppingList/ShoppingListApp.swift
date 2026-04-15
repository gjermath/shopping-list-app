import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    @StateObject private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.background.ignoresSafeArea())
                } else if authService.isSignedIn {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .environmentObject(authService)
        }
    }
}
