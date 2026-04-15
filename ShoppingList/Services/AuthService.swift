import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = true

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoading = false
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    var isSignedIn: Bool { user != nil }

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce else {
                throw AuthError.invalidCredential
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            try await createUserDocumentIfNeeded(authResult.user)

        case .failure(let error):
            throw error
        }
    }

    #if DEBUG
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        try await createUserDocumentIfNeeded(result.user)
    }
    #endif

    func signOut() throws {
        try Auth.auth().signOut()
    }

    private func createUserDocumentIfNeeded(_ user: FirebaseAuth.User) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.uid)
        let doc = try await docRef.getDocument()

        if !doc.exists {
            let appUser = AppUser(
                displayName: user.displayName ?? "User",
                email: user.email ?? "",
                photoURL: user.photoURL?.absoluteString,
                createdAt: Date(),
                lastActiveAt: Date(),
                settings: AppUser.UserSettings()
            )
            try docRef.setData(from: appUser)
        } else {
            try await docRef.updateData(["lastActiveAt": FieldValue.serverTimestamp()])
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                precondition(status == errSecSuccess)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return String(localized: "Unable to process Apple Sign-In credentials.")
        }
    }
}
