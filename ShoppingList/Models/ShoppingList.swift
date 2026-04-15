import Foundation
import FirebaseFirestore

struct ShoppingList: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var inviteCode: String
    var language: String?

    var currentUserId: String? = nil

    var isMember: Bool {
        guard let userId = currentUserId else { return false }
        return memberIds.contains(userId)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, ownerId, memberIds, createdAt, updatedAt, inviteCode, language
    }
}

extension ShoppingList: Hashable {
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
