// ShoppingList/Intents/ShoppingListAppShortcuts.swift
import AppIntents

struct ShoppingListAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddItemsIntent(),
            phrases: [
                "Add to my shopping list in \(.applicationName)",
                "Add items in \(.applicationName)",
                "Shopping list in \(.applicationName)",
            ],
            shortTitle: "Add to Shopping List",
            systemImageName: "cart.badge.plus"
        )
    }
}
