import SwiftUI

struct ListDetailView: View {
    let list: ShoppingList
    @EnvironmentObject var languageService: LanguageService
    @StateObject private var itemService = ItemService()
    @StateObject private var speechService = SpeechService()
    @State private var inputText = ""

    // Sheet state
    @State private var showListSettings = false
    @State private var showSuggestions = false
    @State private var showDuplicates = false
    @State private var showCamera = false
    @State private var showPhotoConfirmation = false
    @State private var editingItem: Item?

    // Photo state
    @State private var capturedImage: UIImage?
    @State private var parsedPhotoItems: [ParsedItem] = []
    @State private var isParsingPhoto = false

    // Duplicates state
    @State private var duplicateGroups: [DuplicateGroup] = []

    private let photoService = PhotoService()
    private let aiService = AIService()

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
                            },
                            listLanguage: list.language
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
                onMicTap: {
                    if speechService.isRecording {
                        speechService.stopRecording()
                        let text = speechService.transcribedText.trimmingCharacters(in: .whitespaces)
                        if !text.isEmpty {
                            Task {
                                try? await itemService.addItem(listId: list.id ?? "", rawInput: text, source: .voice)
                            }
                        }
                    } else {
                        try? speechService.startRecording()
                    }
                },
                onCameraTap: {
                    showCamera = true
                },
                isRecording: speechService.isRecording
            )
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showListSettings = true
                    } label: {
                        Label("List Settings", systemImage: "gearshape")
                    }

                    Button {
                        showSuggestions = true
                    } label: {
                        Label("Suggestions", systemImage: "sparkles")
                    }

                    Button {
                        Task { await runDuplicateCheck() }
                    } label: {
                        Label("Check Duplicates", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            itemService.startListening(listId: list.id ?? "")
            speechService.requestAuthorization()
        }
        .onDisappear { itemService.stopListening() }
        .sheet(isPresented: $showListSettings) {
            ListSettingsView(list: list)
        }
        .sheet(isPresented: $showSuggestions) {
            SuggestionsView(listId: list.id ?? "") { item in
                Task { try? await itemService.addItem(listId: list.id ?? "", rawInput: item) }
            }
        }
        .sheet(isPresented: $showDuplicates) {
            DuplicateReviewView(
                groups: duplicateGroups,
                onMerge: { group in
                    Task {
                        for itemName in group.items where itemName != group.suggestion {
                            if let item = itemService.items.first(where: { $0.name == itemName }) {
                                try? await itemService.deleteItem(listId: list.id ?? "", item: item)
                            }
                        }
                    }
                },
                onDismiss: { showDuplicates = false }
            )
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage)
        }
        .sheet(isPresented: $showPhotoConfirmation) {
            PhotoConfirmationView(
                items: parsedPhotoItems,
                onConfirm: { items in
                    showPhotoConfirmation = false
                    Task {
                        for item in items {
                            try? await itemService.addItem(
                                listId: list.id ?? "",
                                rawInput: item.name,
                                source: .photo
                            )
                        }
                    }
                },
                onCancel: { showPhotoConfirmation = false }
            )
        }
        .sheet(item: $editingItem) { item in
            EditItemView(item: item) { name, quantity, category in
                Task {
                    try? await itemService.updateItem(
                        listId: list.id ?? "",
                        item: item,
                        name: name,
                        quantity: quantity,
                        category: category
                    )
                }
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let image = newImage else { return }
            Task {
                isParsingPhoto = true
                do {
                    let imageUrl = try await photoService.uploadImage(image)
                    parsedPhotoItems = try await aiService.parseImage(imageUrl: imageUrl)
                    showPhotoConfirmation = true
                } catch {
                    // Photo parsing failed — user can retry
                }
                isParsingPhoto = false
                capturedImage = nil
            }
        }
    }

    private func runDuplicateCheck() async {
        do {
            duplicateGroups = try await aiService.reviewDuplicates(listId: list.id ?? "")
            showDuplicates = true
        } catch {
            // Duplicate check failed
        }
    }
}
