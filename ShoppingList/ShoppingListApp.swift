import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var languageService = LanguageService()

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
                        .onAppear { languageService.loadLanguage() }
                } else {
                    SignInView()
                }
            }
            .environmentObject(authService)
            .environmentObject(languageService)
            .environment(\.locale, languageService.resolvedLocale)
            .onAppear {
                notificationService.requestPermission()
            }
        }
    }
}
