import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var photoURL: String?
    var createdAt: Date
    var lastActiveAt: Date
    var defaultListId: String?
    var settings: UserSettings

    struct UserSettings: Codable {
        var notificationsEnabled: Bool = true
        var language: String?
    }
}
