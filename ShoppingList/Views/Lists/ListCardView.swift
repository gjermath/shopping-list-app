import SwiftUI

struct ListCardView: View {
    let list: ShoppingList
    let itemCount: Int

    var body: some View {
        HStack(spacing: Theme.paddingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)

                Text("\(itemCount) items")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                MemberAvatarStack(memberCount: list.memberIds.count)

                Text(list.updatedAt.relativeDescription)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surfaceWhite)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: Theme.cardShadow, y: 2)
    }
}
