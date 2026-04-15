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
