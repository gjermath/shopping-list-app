import Foundation
import FirebaseFirestore

enum HistoryAction: String, Codable {
    case added
    case completed
    case removed
    case reAdded = "re-added"
}

struct HistoryEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var itemName: String
    var category: String?
    var action: HistoryAction
    var userId: String
    var timestamp: Date
    var purchaseCount: Int = 0
}
