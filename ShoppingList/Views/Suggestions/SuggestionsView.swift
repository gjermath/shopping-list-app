import SwiftUI

struct SuggestionsView: View {
    let listId: String
    let onAddItem: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var suggestions: [String] = []
    @State private var isLoading = true
    @State private var addedItems: Set<String> = []

    private let aiService = AIService()

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Finding suggestions...")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else if suggestions.isEmpty {
                    ContentUnavailableView(
                        "No Suggestions Yet",
                        systemImage: "sparkles",
                        description: Text("Suggestions improve as you use your lists more")
                    )
                } else {
                    Section("Frequently Bought") {
                        ForEach(suggestions, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(addedItems.contains(item) ? Theme.textSecondary : Theme.textPrimary)

                                Spacer()

                                if addedItems.contains(item) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.secondaryGreen)
                                } else {
                                    Button {
                                        onAddItem(item)
                                        addedItems.insert(item)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Theme.primaryGreen)
                                            .font(.system(size: 22))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                do {
                    suggestions = try await aiService.suggestFrequentItems(listId: listId)
                } catch {
                    suggestions = []
                }
                isLoading = false
            }
        }
    }
}
