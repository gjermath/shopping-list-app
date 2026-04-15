import Foundation
import FirebaseFirestore

class HistoryService {
    private let db = Firestore.firestore()

    func recordAction(
        listId: String,
        itemName: String,
        category: String? = nil,
        action: HistoryAction,
        userId: String
    ) async throws {
        let entry = HistoryEntry(
            itemName: itemName,
            category: category,
            action: action,
            userId: userId,
            timestamp: Date(),
            purchaseCount: action == .completed ? 1 : 0
        )

        try db.collection("lists").document(listId)
            .collection("history")
            .addDocument(from: entry)

        if action == .completed {
            let existing = try await db.collection("lists").document(listId)
                .collection("history")
                .whereField("itemName", isEqualTo: itemName)
                .whereField("action", isEqualTo: HistoryAction.completed.rawValue)
                .getDocuments()

            for doc in existing.documents {
                let currentCount = doc.data()["purchaseCount"] as? Int ?? 0
                try await doc.reference.updateData(["purchaseCount": currentCount + 1])
            }
        }
    }

    func getHistory(listId: String, limit: Int = 50) async throws -> [HistoryEntry] {
        let snapshot = try await db.collection("lists").document(listId)
            .collection("history")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: HistoryEntry.self) }
    }

    func getFrequentItems(listId: String) async throws -> [HistoryEntry] {
        let snapshot = try await db.collection("lists").document(listId)
            .collection("history")
            .whereField("action", isEqualTo: HistoryAction.completed.rawValue)
            .order(by: "purchaseCount", descending: true)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: HistoryEntry.self) }
    }
}
