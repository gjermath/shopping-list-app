import SwiftUI

struct ListSettingsView: View {
    let list: ShoppingList
    @EnvironmentObject var listService: ListService
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var showInvite = false
    @State private var showDeleteConfirmation = false

    init(list: ShoppingList) {
        self.list = list
        self._name = State(initialValue: list.name)
    }

    private var isOwner: Bool {
        list.ownerId == list.currentUserId
    }

    var body: some View {
        NavigationStack {
            List {
                Section("List Name") {
                    TextField("Name", text: $name)
                        .onSubmit {
                            Task {
                                try? await listService.updateListName(list.id ?? "", name: name)
                            }
                        }
                }

                Section("Members") {
                    ForEach(list.memberIds, id: \.self) { memberId in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.secondaryGreen)
                            Text(memberId == list.ownerId ? "Owner" : "Member")
                                .font(Theme.bodyFont)
                            Spacer()
                            if memberId == list.ownerId {
                                Text("Owner")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }

                    Button {
                        showInvite = true
                    } label: {
                        Label("Invite Members", systemImage: "person.badge.plus")
                    }
                }

                if isOwner {
                    Section {
                        Button("Delete List", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                } else {
                    Section {
                        Button("Leave List", role: .destructive) {
                            Task {
                                try? await listService.leaveList(list.id ?? "")
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("List Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showInvite) {
                InviteView(list: list)
            }
            .confirmationDialog("Delete List", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await listService.deleteList(list.id ?? "")
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete the list for all members.")
            }
        }
    }
}
