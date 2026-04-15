import SwiftUI

struct ActivityTabView: View {
    var body: some View {
        NavigationStack {
            Text("Activity coming soon")
                .foregroundColor(Theme.textSecondary)
                .navigationTitle("Activity")
        }
    }
}
