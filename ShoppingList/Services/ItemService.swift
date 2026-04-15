import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ItemService: ObservableObject {
    @Published var items: [Item] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let historyService = HistoryService()

    var activeItems: [Item] {
        items.filter { $0.status == .active }
    }

    var completedItems: [Item] {
        items.filter { $0.status == .completed && ($0.completedAt.map { !$0.isOlderThan24Hours } ?? true) }
    }

    var itemsByCategory: [(ItemCategory, [Item])] {
        let grouped = Dictionary(grouping: activeItems) { $0.resolvedCategory }
        return grouped
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
            .map { ($0.key, $0.value.sorted { $0.addedAt > $1.addedAt }) }
    }

    func startListening(listId: String) {
        listener = db.collection("lists").document(listId)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.items = documents.compactMap { try? $0.data(as: Item.self) }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addItem(listId: String, rawInput: String, source: ItemSource = .text) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let item = Item(
            name: rawInput,
            rawInput: rawInput,
            addedBy: userId,
            addedAt: Date(),
            source: source
        )

        try db.collection("lists").document(listId)
            .collection("items")
            .addDocument(from: item)

        try await historyService.recordAction(
            listId: listId,
            itemName: rawInput,
            action: .added,
            userId: userId
        )

        try await db.collection("lists").document(listId).updateData([
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func toggleComplete(listId: String, item: Item) async throws {
        guard let itemId = item.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        if item.isCompleted {
            try await db.collection("lists").document(listId)
                .collection("items").document(itemId)
                .updateData([
                    "status": ItemStatus.active.rawValue,
                    "completedAt": FieldValue.delete(),
                    "completedBy": FieldValue.delete()
                ])
        } else {
            try await db.collection("lists").document(listId)
                .collection("items").document(itemId)
                .updateData([
                    "status": ItemStatus.completed.rawValue,
                    "completedAt": FieldValue.serverTimestamp(),
                    "completedBy": userId
                ])

            try await historyService.recordAction(
                listId: listId,
                itemName: item.name,
                category: item.category,
                action: .completed,
                userId: userId
            )
        }
    }

    func toggleFlag(listId: String, item: Item) async throws {
        guard let itemId = item.id else { return }
        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .updateData(["flagged": !item.flagged])
    }

    func updateItem(listId: String, item: Item, name: String, quantity: String?, category: String?) async throws {
        guard let itemId = item.id else { return }
        var updates: [String: Any] = ["name": name]
        if let quantity { updates["quantity"] = quantity }
        if let category { updates["category"] = category }
        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .updateData(updates)
    }

    func deleteItem(listId: String, item: Item) async throws {
        guard let itemId = item.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .delete()

        try await historyService.recordAction(
            listId: listId,
            itemName: item.name,
            category: item.category,
            action: .removed,
            userId: userId
        )
    }
}
