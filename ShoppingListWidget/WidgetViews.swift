import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: ShoppingListEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: ShoppingListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.196))
                    .font(.system(size: 14))
                Text(entry.listName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
            }

            Text("\(entry.totalCount) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            ForEach(entry.items.prefix(3)) { item in
                HStack(spacing: 4) {
                    if item.isFlagged {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0))
                    }
                    Text(item.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.99, blue: 0.976), for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: ShoppingListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.196))
                Text(entry.listName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(entry.totalCount) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            ForEach(entry.items.prefix(4)) { item in
                HStack(spacing: 6) {
                    if item.isFlagged {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0))
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    Text(item.name)
                        .font(.system(size: 13))
                        .lineLimit(1)

                    Spacer()

                    Text(item.category)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.99, blue: 0.976), for: .widget)
    }
}
