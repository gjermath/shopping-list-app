import SwiftUI

struct ItemRowView: View {
    let item: Item
    let onToggleComplete: () -> Void
    let onToggleFlag: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FlagToggle(isFlagged: item.flagged, action: onToggleFlag)

            Button(action: onToggleComplete) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(item.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                            .strikethrough(item.isCompleted)

                        if let quantity = item.quantity, !quantity.isEmpty {
                            Text(quantity)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.secondaryGreen)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, Theme.paddingMedium)
    }
}
