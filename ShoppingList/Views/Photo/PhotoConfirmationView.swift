import SwiftUI

struct PhotoConfirmationView: View {
    let items: [ParsedItem]
    let onConfirm: ([ParsedItem]) -> Void
    let onCancel: () -> Void

    @State private var selectedItems: Set<String>

    init(items: [ParsedItem], onConfirm: @escaping ([ParsedItem]) -> Void, onCancel: @escaping () -> Void) {
        self.items = items
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self._selectedItems = State(initialValue: Set(items.map(\.id)))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { item in
                        HStack {
                            Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedItems.contains(item.id) ? Theme.primaryGreen : Theme.textSecondary)

                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(Theme.bodyFont)
                                if let quantity = item.quantity {
                                    Text(quantity)
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }

                            Spacer()

                            if let category = item.category {
                                Text(category)
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedItems.contains(item.id) {
                                selectedItems.remove(item.id)
                            } else {
                                selectedItems.insert(item.id)
                            }
                        }
                    }
                } header: {
                    Text("I found these items")
                }
            }
            .navigationTitle("Add from Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selectedItems.count)") {
                        let selected = items.filter { selectedItems.contains($0.id) }
                        onConfirm(selected)
                    }
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
    }
}
