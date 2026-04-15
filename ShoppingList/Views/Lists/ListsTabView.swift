import SwiftUI

struct ListsTabView: View {
    @EnvironmentObject var listService: ListService
    @State private var showCreateList = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.paddingSmall) {
                    ForEach(listService.lists) { list in
                        NavigationLink(value: list) {
                            ListCardView(list: list, itemCount: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.paddingMedium)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.primaryGreen)
                }
            }
            .navigationDestination(for: ShoppingList.self) { list in
                Text("List Detail: \(list.name)")
            }
            .sheet(isPresented: $showCreateList) {
                CreateListView()
            }
            .overlay {
                if listService.lists.isEmpty && !listService.isLoading {
                    ContentUnavailableView(
                        "No Lists Yet",
                        systemImage: "cart",
                        description: Text("Tap + to create your first shopping list")
                    )
                }
            }
        }
    }
}
