import SwiftUI

struct OfflineBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: Theme.paddingSmall) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("Offline — changes will sync when connected")
                    .font(Theme.captionFont)
            }
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, Theme.paddingMedium)
            .frame(maxWidth: .infinity)
            .background(Theme.textSecondary)
        }
    }
}
