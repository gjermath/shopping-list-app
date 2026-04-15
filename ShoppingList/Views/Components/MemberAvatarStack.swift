import SwiftUI

struct MemberAvatarStack: View {
    let memberCount: Int
    let maxDisplay: Int = 3

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<min(memberCount, maxDisplay), id: \.self) { index in
                Circle()
                    .fill(Theme.secondaryGreen.opacity(0.3 + Double(index) * 0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.primaryGreen)
                    )
                    .overlay(Circle().stroke(Theme.surfaceWhite, lineWidth: 2))
            }

            if memberCount > maxDisplay {
                Text("+\(memberCount - maxDisplay)")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }
}
