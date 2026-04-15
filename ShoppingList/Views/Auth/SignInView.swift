import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            Spacer()

            VStack(spacing: Theme.paddingSmall) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.primaryGreen)

                Text("Shopping List")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)

                Text("Keep your family's groceries in sync")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                authService.handleSignInWithAppleRequest(request)
            } onCompletion: { result in
                Task {
                    do {
                        try await authService.handleSignInWithAppleCompletion(result)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(Theme.cornerRadius)
            .padding(.horizontal, Theme.paddingLarge)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .foregroundColor(.red)
            }

            Spacer()
                .frame(height: 40)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
