import SwiftUI

struct CategorySectionView: View {
    let category: ItemCategory
    let items: [Item]
    let onToggleComplete: (Item) -> Void
    let onToggleFlag: (Item) -> Void
    let onDelete: (Item) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("\(category.emoji) \(category.rawValue)")
                        .font(Theme.captionFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))

                    Spacer()

                    Text("\(items.count)")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))
                }
                .padding(.horizontal, Theme.paddingMedium)
                .padding(.vertical, Theme.paddingSmall)
                .background(Theme.categoryColor(category.rawValue))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(items) { item in
                    ItemRowView(
                        item: item,
                        onToggleComplete: { onToggleComplete(item) },
                        onToggleFlag: { onToggleFlag(item) }
                    )
                }
            }
        }
    }
}
