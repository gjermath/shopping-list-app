import SwiftUI

struct ListDetailView: View {
    let list: ShoppingList
    @StateObject private var itemService = ItemService()
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: Theme.paddingSmall) {
                    ForEach(itemService.itemsByCategory, id: \.0) { category, items in
                        CategorySectionView(
                            category: category,
                            items: items,
                            onToggleComplete: { item in
                                Task { try? await itemService.toggleComplete(listId: list.id ?? "", item: item) }
                            },
                            onToggleFlag: { item in
                                Task { try? await itemService.toggleFlag(listId: list.id ?? "", item: item) }
                            },
                            onDelete: { item in
                                Task { try? await itemService.deleteItem(listId: list.id ?? "", item: item) }
                            }
                        )
                    }

                    CompletedSectionView(
                        items: itemService.completedItems,
                        onToggleComplete: { item in
                            Task { try? await itemService.toggleComplete(listId: list.id ?? "", item: item) }
                        }
                    )
                }
                .padding(Theme.paddingMedium)
            }

            InputBarView(
                text: $inputText,
                onSubmit: {
                    let text = inputText.trimmingCharacters(in: .whitespaces)
                    guard !text.isEmpty else { return }
                    inputText = ""
                    Task { try? await itemService.addItem(listId: list.id ?? "", rawInput: text) }
                },
                onMicTap: { },
                onCameraTap: { }
            )
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { itemService.startListening(listId: list.id ?? "") }
        .onDisappear { itemService.stopListening() }
    }
}
