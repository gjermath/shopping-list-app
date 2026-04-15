import SwiftUI

struct EditItemView: View {
    let item: Item
    let onSave: (String, String?, String?) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var quantity: String
    @State private var selectedCategory: ItemCategory

    init(item: Item, onSave: @escaping (String, String?, String?) -> Void) {
        self.item = item
        self.onSave = onSave
        self._name = State(initialValue: item.name)
        self._quantity = State(initialValue: item.quantity ?? "")
        self._selectedCategory = State(initialValue: item.resolvedCategory)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    TextField("Quantity (optional)", text: $quantity)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ItemCategory.allCases) { category in
                            Text("\(category.emoji) \(category.rawValue)")
                                .tag(category)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name,
                            quantity.isEmpty ? nil : quantity,
                            selectedCategory.rawValue
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
