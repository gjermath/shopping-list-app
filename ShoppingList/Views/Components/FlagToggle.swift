import SwiftUI

struct FlagToggle: View {
    let isFlagged: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFlagged ? "star.fill" : "star")
                .foregroundColor(isFlagged ? Theme.flagAmber : Theme.textSecondary.opacity(0.4))
                .font(.system(size: 16))
        }
        .buttonStyle(.plain)
    }
}
