# Siri Integration via App Intents — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Siri voice support for adding items to shopping lists via "Add milk to my shopping list".

**Architecture:** Single `AddItemsIntent` (App Intents framework, iOS 17+) with smart list resolution. Static helper methods on existing services enable Firestore access outside the UI lifecycle. `AppShortcutsProvider` registers Siri phrases.

**Tech Stack:** Swift App Intents framework, Firebase Auth, Cloud Firestore

---

## File Structure

```
ShoppingList/
├── Intents/
│   ├── AddItemsIntent.swift           # AppIntent + ShoppingListEntity + list resolution
│   └── ShoppingListAppShortcuts.swift # AppShortcutsProvider with Siri phrases
├── Services/
│   ├── ListService.swift              # Add static fetchLists(for:) method
│   └── ItemService.swift              # Add static addItemDirectly(...) method
```

---

### Task 1: Add Static Helper Methods to Services

**Files:**
- Modify: `ShoppingList/Services/ListService.swift`
- Modify: `ShoppingList/Services/ItemService.swift`

These static methods allow the App Intent to access Firestore without needing the `@MainActor`-bound `@StateObject` instances that the UI uses.

- [ ] **Step 1: Add `fetchLists(for:)` to ListService**

Add this static method at the end of the `ListService` class, before the closing brace (line 99):

```swift
    // MARK: - Static helpers for App Intents

    static func fetchLists(for userId: String) async throws -> [ShoppingList] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("lists")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var list = try? doc.data(as: ShoppingList.self)
            list?.currentUserId = userId
            return list
        }
    }

    static func fetchUserDefaultListId(for userId: String) async throws -> String? {
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(userId).getDocument()
        return doc.data()?["defaultListId"] as? String
    }
```

- [ ] **Step 2: Add `addItemDirectly(...)` to ItemService**

Add this static method at the end of the `ItemService` class, before the closing brace (line 133):

```swift
    // MARK: - Static helpers for App Intents

    static func addItemDirectly(
        listId: String,
        rawInput: String,
        userId: String,
        source: ItemSource = .text
    ) async throws {
        let db = Firestore.firestore()

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

        let historyService = HistoryService()
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
```

- [ ] **Step 3: Verify build**

Run:
```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/Services/ListService.swift ShoppingList/Services/ItemService.swift
git commit -m "feat: add static Firestore helpers for App Intents access"
```

---

### Task 2: Create ShoppingListEntity (App Entity for Siri Disambiguation)

**Files:**
- Create: `ShoppingList/Intents/AddItemsIntent.swift` (first part — entity only)

The `AppEntity` represents a shopping list in the App Intents system. Siri uses it to present list options when disambiguation is needed.

- [ ] **Step 1: Create the Intents directory and AddItemsIntent.swift with the entity**

```swift
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
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Intents/AddItemsIntent.swift
git commit -m "feat: add ShoppingListEntity for Siri list disambiguation"
```

---

### Task 3: Create AddItemsIntent

**Files:**
- Modify: `ShoppingList/Intents/AddItemsIntent.swift` (append the intent struct)

- [ ] **Step 1: Append the AddItemsIntent struct to AddItemsIntent.swift**

Add this after the `ShoppingListQuery` struct:

```swift
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
            // User specified a list name — find it (case-insensitive)
            if let match = lists.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
                targetList = match
            } else {
                // No match — pick the best option
                if lists.count == 1 {
                    targetList = lists[0]
                } else {
                    return .result(dialog: "I couldn't find a list called \"\(name)\". Try saying the exact list name.")
                }
            }
        } else if lists.count == 1 {
            // Only one list — use it
            targetList = lists[0]
        } else if let defaultId = try? await ListService.fetchUserDefaultListId(for: userId),
                  let defaultList = lists.first(where: { $0.id == defaultId }) {
            // Use default list
            targetList = defaultList
        } else {
            // Multiple lists, no default — ask
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
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Intents/AddItemsIntent.swift
git commit -m "feat: add AddItemsIntent with smart list resolution"
```

---

### Task 4: Create AppShortcutsProvider

**Files:**
- Create: `ShoppingList/Intents/ShoppingListAppShortcuts.swift`

This registers Siri phrases so users can discover the feature in Settings > Siri & Search.

- [ ] **Step 1: Create the shortcuts provider**

```swift
// ShoppingList/Intents/ShoppingListAppShortcuts.swift
import AppIntents

struct ShoppingListAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddItemsIntent(),
            phrases: [
                "Add \(\.$itemText) to my shopping list",
                "Add \(\.$itemText) to \(\.$listName) in \(.applicationName)",
                "Add items to \(.applicationName)",
            ],
            shortTitle: "Add to Shopping List",
            systemImageName: "cart.badge.plus"
        )
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Intents/ShoppingListAppShortcuts.swift
git commit -m "feat: add AppShortcutsProvider with Siri phrases for item addition"
```

---

### Task 5: Regenerate Xcode Project & Final Verification

**Files:**
- No new files — just regenerate and verify

The new `Intents/` directory needs to be picked up by XcodeGen.

- [ ] **Step 1: Regenerate the Xcode project**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app && xcodegen generate
```

Expected: `Created project at .../ShoppingList.xcodeproj`

- [ ] **Step 2: Full build verification**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit if project file changed**

```bash
git add ShoppingList.xcodeproj/ project.yml
git commit -m "chore: regenerate Xcode project with Intents directory"
```

---

## Summary

| Task | What it builds |
|------|----------------|
| 1. Static service helpers | `ListService.fetchLists(for:)`, `ListService.fetchUserDefaultListId(for:)`, `ItemService.addItemDirectly(...)` |
| 2. ShoppingListEntity | App entity + query for Siri list disambiguation |
| 3. AddItemsIntent | The core intent with smart list resolution and Firestore write |
| 4. AppShortcutsProvider | Siri phrase registration for discoverability |
| 5. Project regeneration | XcodeGen picks up new Intents/ directory |
