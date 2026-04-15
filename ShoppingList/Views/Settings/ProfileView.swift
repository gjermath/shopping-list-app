import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var languageService: LanguageService

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.secondaryGreen)

                        VStack(alignment: .leading) {
                            Text(authService.user?.displayName ?? "User")
                                .font(Theme.headlineFont)
                            Text(authService.user?.email ?? "")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preferences") {
                    Picker(String(localized: "Language"), selection: Binding(
                        get: { languageService.appLanguage ?? "__device__" },
                        set: { newValue in
                            let lang: String? = newValue == "__device__" ? nil : newValue
                            Task { try? await languageService.updateAppLanguage(lang) }
                        }
                    )) {
                        Text(String(localized: "Device Default")).tag("__device__")
                        Text("English").tag("en")
                        Text("Dansk").tag("da")
                    }
                    NavigationLink {
                        Text("Notification settings")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
