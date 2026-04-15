// ShoppingList/Intents/AddItemsIntent.swift
import AppIntents
import FirebaseAuth
import FirebaseFirestore

// MARK: - ShoppingListEntity

struct ShoppingListEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Shopping List")
    static var defaultQuery = ShoppingListQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from list: ShoppingList) {
        self.id = list.id ?? ""
        self.name = list.name
    }
}

struct ShoppingListQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ShoppingListEntity] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        let lists = try await ListService.fetchLists(for: userId)
        return lists
            .filter { identifiers.contains($0.id ?? "") }
            .map { ShoppingListEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [ShoppingListEntity] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        let lists = try await ListService.fetchLists(for: userId)
        return lists.map { ShoppingListEntity(from: $0) }
    }
}
