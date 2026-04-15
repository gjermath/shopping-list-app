import SwiftUI

struct ActivityTabView: View {
    @EnvironmentObject var listService: ListService
    @State private var allHistory: [HistoryEntry] = []
    @State private var isLoading = true

    private let historyService = HistoryService()

    var body: some View {
        NavigationStack {
            List {
                if allHistory.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Activity Yet",
                        systemImage: "clock",
                        description: Text("Activity will appear here as you use your lists")
                    )
                } else {
                    ForEach(allHistory) { entry in
                        ActivityRowView(entry: entry)
                    }
                }
            }
            .navigationTitle("Activity")
            .refreshable { await loadHistory() }
            .task { await loadHistory() }
        }
    }

    private func loadHistory() async {
        isLoading = true
        var entries: [HistoryEntry] = []

        for list in listService.lists {
            guard let listId = list.id else { continue }
            if let history = try? await historyService.getHistory(listId: listId, limit: 20) {
                entries.append(contentsOf: history)
            }
        }

        allHistory = entries.sorted { $0.timestamp > $1.timestamp }
        isLoading = false
    }
}
