import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

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
