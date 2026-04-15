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

// MARK: - AddItemsIntent

struct AddItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Shopping List"
    static var description = IntentDescription("Add items to a shopping list")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Items")
    var itemText: String

    @Parameter(title: "List", optionsProvider: ShoppingListOptionsProvider())
    var listName: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. Check auth
        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "You need to open Shopping List and sign in first.")
        }

        // 2. Fetch user's lists
        let lists: [ShoppingList]
        do {
            lists = try await ListService.fetchLists(for: userId)
        } catch {
            return .result(dialog: "Sorry, I couldn't reach your lists. Try again in a moment.")
        }

        guard !lists.isEmpty else {
            return .result(dialog: "You don't have any shopping lists yet. Open the app to create one.")
        }

        // 3. Resolve target list
        let targetList: ShoppingList

        if let name = listName {
            if let match = lists.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
                targetList = match
            } else {
                if lists.count == 1 {
                    targetList = lists[0]
                } else {
                    return .result(dialog: "I couldn't find a list called \"\(name)\". Try saying the exact list name.")
                }
            }
        } else if lists.count == 1 {
            targetList = lists[0]
        } else if let defaultId = try? await ListService.fetchUserDefaultListId(for: userId),
                  let defaultList = lists.first(where: { $0.id == defaultId }) {
            targetList = defaultList
        } else {
            return .result(dialog: "You have multiple lists. Try saying \"Add \(itemText) to\" followed by the list name.")
        }

        // 4. Add the item
        guard let listId = targetList.id else {
            return .result(dialog: "Sorry, something went wrong. Try again.")
        }

        do {
            try await ItemService.addItemDirectly(
                listId: listId,
                rawInput: itemText,
                userId: userId,
                source: .voice
            )
        } catch {
            return .result(dialog: "Sorry, I couldn't add that. Try again in a moment.")
        }

        return .result(dialog: "Added \(itemText) to \(targetList.name).")
    }
}

// MARK: - Options Provider

struct ShoppingListOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        let lists = try await ListService.fetchLists(for: userId)
        return lists.map(\.name)
    }
}
