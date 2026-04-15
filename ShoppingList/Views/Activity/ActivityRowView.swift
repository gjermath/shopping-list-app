import SwiftUI

struct ActivityRowView: View {
    let entry: HistoryEntry

    var actionIcon: String {
        switch entry.action {
        case .added: return "plus.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .removed: return "minus.circle.fill"
        case .reAdded: return "arrow.uturn.left.circle.fill"
        }
    }

    var actionColor: Color {
        switch entry.action {
        case .added: return Theme.primaryGreen
        case .completed: return Theme.secondaryGreen
        case .removed: return .red
        case .reAdded: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionIcon)
                .foregroundColor(actionColor)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.itemName)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    Text(entry.action.rawValue.capitalized)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text(entry.timestamp.relativeDescription)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            if let category = entry.category {
                Text(category)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.categoryTextColor(category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.categoryColor(category))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
