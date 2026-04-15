import WidgetKit
import SwiftUI

struct ShoppingListEntry: TimelineEntry {
    let date: Date
    let listName: String
    let items: [WidgetItem]
    let totalCount: Int
}

struct WidgetItem: Identifiable {
    let id = UUID()
    let name: String
    let isFlagged: Bool
    let category: String
}

struct ShoppingListProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoppingListEntry {
        ShoppingListEntry(
            date: Date(),
            listName: "Groceries",
            items: [
                WidgetItem(name: "Milk", isFlagged: true, category: "Dairy"),
                WidgetItem(name: "Bread", isFlagged: false, category: "Bakery"),
                WidgetItem(name: "Eggs", isFlagged: false, category: "Dairy"),
            ],
            totalCount: 8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShoppingListEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingListEntry>) -> Void) {
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

@main
struct ShoppingListWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShoppingListWidget()
    }
}

struct ShoppingListWidget: Widget {
    let kind = "ShoppingListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoppingListProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Shopping List")
        .description("See your shopping list items at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
