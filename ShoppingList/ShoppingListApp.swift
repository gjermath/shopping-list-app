import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
