import Foundation
import FirebaseFirestore

enum ItemStatus: String, Codable {
    case active
    case completed
}

enum ItemSource: String, Codable {
    case text
    case voice
    case photo
}

struct Item: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var rawInput: String?
    var quantity: String?
    var category: String?
    var flagged: Bool = false
    var status: ItemStatus = .active
    var completedAt: Date?
    var completedBy: String?
    var addedBy: String
    var addedAt: Date
    var source: ItemSource = .text

    var isCompleted: Bool { status == .completed }

    var resolvedCategory: ItemCategory {
        guard let category = category,
              let parsed = ItemCategory(rawValue: category) else {
            return .other
        }
        return parsed
    }
}
