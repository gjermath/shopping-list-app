# Siri Integration via App Intents — Design Spec

## Overview

Add Siri voice support for adding items to shopping lists using the iOS 17 App Intents framework. Users can say things like "Add milk to my shopping list" or "Add eggs and bread to Weekly Groceries" and have items added to the correct list with AI parsing handled by the existing Cloud Functions pipeline.

## Approach

Use the App Intents framework (iOS 17+). A single `AddItemsIntent` struct handles Siri, Shortcuts, and Spotlight. Runs in-process — no separate extension target needed. Reuses existing `ItemService` and `ListService`.

## Intent: AddItemsIntent

### Parameters

- `itemText: String` (required) — the raw input, e.g. "milk" or "eggs and bread". Siri extracts this from the utterance.
- `listName: String` (optional) — the target list name, e.g. "Weekly Groceries". If omitted, resolved via smart default logic.

### List Resolution (Smart Default)

Priority order:
1. If `listName` is provided, find the list whose name matches (case-insensitive). If no match, Siri asks "I couldn't find that list. Which one?"
2. If the user has exactly one list, use it — no question asked.
3. If the user has a `defaultListId` set in their profile, use that list.
4. Otherwise, Siri asks: "Which list should I add this to?" with the user's lists as options.

### Perform Logic

1. Resolve the target list using the smart default logic above.
2. Call `ItemService.addItem(listId:rawInput:source:)` with `source: .voice`.
3. The existing `onItemCreated` Cloud Function triggers automatically to parse natural language, split multi-item inputs, and assign categories via Gemini.
4. Return a Siri confirmation dialog: "Added [items] to [list name]".

### Error Handling

- Not signed in: "You need to open Shopping List and sign in first."
- No lists exist: "You don't have any shopping lists yet. Open the app to create one."
- Firestore write fails: "Sorry, I couldn't add that. Try again in a moment."

## Files

### Create: `ShoppingList/Intents/AddItemsIntent.swift`

The `AppIntent` struct with:
- `@Parameter` properties for `itemText` and `listName`
- `perform()` method implementing list resolution and item addition
- `IntentDialog` responses for success and error cases
- An `AppEntity` for `ShoppingListEntity` to enable Siri disambiguation when multiple lists exist

### Create: `ShoppingList/Intents/ShoppingListAppShortcuts.swift`

An `AppShortcutsProvider` that registers suggested Siri phrases:
- "Add to shopping list"
- "Add items to shopping list"

These surface in Settings > Siri & Search so users discover the capability.

### Modify: `ShoppingList/Services/ListService.swift`

Add a static async method `fetchLists(for userId: String) -> [ShoppingList]` that performs a one-shot Firestore query (no snapshot listener). Needed because the intent runs outside the normal UI lifecycle where the listener-based `ListService` is active.

### Modify: `ShoppingList/Services/ItemService.swift`

Add a static async method `addItemDirectly(listId:rawInput:userId:source:)` that writes to Firestore without requiring a `@MainActor`-bound instance. Needed for the same reason — the intent doesn't have access to the view-owned `@StateObject`.

## No Changes Needed

- **project.yml** — App Intents don't require additional capabilities or entitlements.
- **Info.plist** — No additional privacy descriptions needed.
- **Cloud Functions** — The existing `onItemCreated` trigger handles parsing automatically.
- **No new Xcode target** — App Intents run in the main app process.
