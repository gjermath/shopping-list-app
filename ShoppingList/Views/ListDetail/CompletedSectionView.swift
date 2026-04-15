import SwiftUI

struct CompletedSectionView: View {
    let items: [Item]
    let onToggleComplete: (Item) -> Void

    @State private var isExpanded = false

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Theme.secondaryGreen)
                        Text("Completed (\(items.count))")
                            .font(Theme.captionFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.paddingMedium)
                    .padding(.vertical, Theme.paddingSmall)
                    .background(Theme.divider.opacity(0.5))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    ForEach(items) { item in
                        ItemRowView(
                            item: item,
                            onToggleComplete: { onToggleComplete(item) },
                            onToggleFlag: { }
                        )
                    }
                }
            }
        }
    }
}
