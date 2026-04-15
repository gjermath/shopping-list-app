import SwiftUI

struct InviteView: View {
    let list: ShoppingList

    @State private var showShareSheet = false

    private let inviteService = InviteService()

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Theme.primaryGreen)

            Text("Invite to \(list.name)")
                .font(Theme.headlineFont)

            Text("Share this link with family members so they can join your list")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Invite Link")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(Theme.cornerRadius)
            }
        }
        .padding(Theme.paddingLarge)
        .sheet(isPresented: $showShareSheet) {
            if let url = inviteService.generateInviteLink(inviteCode: list.inviteCode, listName: list.name) {
                ShareSheet(items: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
