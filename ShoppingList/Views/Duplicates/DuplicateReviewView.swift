import SwiftUI

struct DuplicateReviewView: View {
    let groups: [DuplicateGroup]
    let onMerge: (DuplicateGroup) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    ContentUnavailableView(
                        "No Duplicates Found",
                        systemImage: "checkmark.circle",
                        description: Text("Your list looks clean!")
                    )
                } else {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.items, id: \.self) { item in
                                HStack {
                                    Text(item)
                                        .font(Theme.bodyFont)
                                    if item == group.suggestion {
                                        Text("suggested")
                                            .font(Theme.captionFont)
                                            .foregroundColor(Theme.secondaryGreen)
                                    }
                                }
                            }

                            HStack {
                                Button("Merge as \"\(group.suggestion)\"") {
                                    onMerge(group)
                                }
                                .foregroundColor(Theme.primaryGreen)

                                Spacer()

                                Button("Keep All") { }
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .font(Theme.captionFont)
                        } header: {
                            Text("Similar Items")
                        }
                    }
                }
            }
            .navigationTitle("Duplicate Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}
