import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onMicTap: () -> Void
    let onCameraTap: () -> Void
    var isRecording: Bool = false

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            TextField("Add items...", text: $text)
                .font(Theme.bodyFont)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            Button(action: onMicTap) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .foregroundColor(isRecording ? .red : Theme.primaryGreen)
                    .font(.system(size: 18))
            }

            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .foregroundColor(Theme.primaryGreen)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 10)
        .background(Theme.surfaceWhite)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.divider),
            alignment: .top
        )
    }
}
