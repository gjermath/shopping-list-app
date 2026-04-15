import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case da = "da"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .da: return "Dansk"
        }
    }
}

@MainActor
class LanguageService: ObservableObject {
    @Published var appLanguage: String?
    private let db = Firestore.firestore()

    var resolvedLocale: Locale {
        Locale(identifier: resolvedAppLanguage)
    }

    var resolvedAppLanguage: String {
        if let lang = appLanguage {
            return lang
        }
        return Self.deviceLanguage
    }

    func resolvedLanguage(for list: ShoppingList) -> String {
        if let listLang = list.language {
            return listLang
        }
        return resolvedAppLanguage
    }

    static var deviceLanguage: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("da") ? "da" : "en"
    }

    func loadLanguage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            let doc = try? await db.collection("users").document(userId).getDocument()
            if let data = doc?.data(),
               let settings = data["settings"] as? [String: Any] {
                self.appLanguage = settings["language"] as? String
            }
        }
    }

    func updateAppLanguage(_ language: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(userId).updateData([
            "settings.language": language as Any
        ])
        appLanguage = language
    }

    func updateListLanguage(_ listId: String, language: String?) async throws {
        try await db.collection("lists").document(listId).updateData([
            "language": language as Any
        ])
    }
}
