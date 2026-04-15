# Language Settings & Full Localization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Danish/English localization with app-level language setting and per-list language override for AI parsing and category names.

**Architecture:** `LanguageService` resolves effective language (list > app > device). Xcode String Catalog (`Localizable.xcstrings`) provides all translated strings. SwiftUI `.environment(\.locale)` at root drives full UI localization. Per-list language overrides affect category display names and the `language` field on new items, which Cloud Functions use for Gemini prompts.

**Tech Stack:** Swift String Catalogs, SwiftUI environment locale, Firebase Firestore, Cloud Functions (TypeScript)

---

## File Structure

```
ShoppingList/
├── Models/
│   ├── User.swift                    # Add language to UserSettings
│   ├── ShoppingList.swift            # Add language field
│   ├── Item.swift                    # Add language field
│   └── ItemCategory.swift            # Add localizedName(for:) method
├── Services/
│   └── LanguageService.swift         # NEW: language resolution + locale provider
├── Resources/
│   └── Localizable.xcstrings         # NEW: String Catalog (en/da)
├── ShoppingListApp.swift             # Apply .environment(\.locale)
├── Views/
│   ├── Settings/ProfileView.swift    # Add language picker
│   ├── Settings/ListSettingsView.swift # Add per-list language picker
│   ├── ListDetail/CategorySectionView.swift # Use list language for categories
│   ├── ListDetail/ListDetailView.swift # Pass language when adding items
│   └── [all other views]             # Replace hardcoded strings with localized keys
functions/
└── src/parseInput.ts                 # Use item language in Gemini prompt
```

---

### Task 1: Data Model Changes

**Files:**
- Modify: `ShoppingList/Models/User.swift`
- Modify: `ShoppingList/Models/ShoppingList.swift`
- Modify: `ShoppingList/Models/Item.swift`

- [ ] **Step 1: Add `language` to `UserSettings`**

In `ShoppingList/Models/User.swift`, add the language field to `UserSettings`:

```swift
struct UserSettings: Codable {
    var notificationsEnabled: Bool = true
    var language: String?
}
```

- [ ] **Step 2: Add `language` to `ShoppingList`**

In `ShoppingList/Models/ShoppingList.swift`, add the field and update `CodingKeys`:

```swift
struct ShoppingList: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var inviteCode: String
    var language: String?

    var currentUserId: String? = nil

    var isMember: Bool {
        guard let userId = currentUserId else { return false }
        return memberIds.contains(userId)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, ownerId, memberIds, createdAt, updatedAt, inviteCode, language
    }
}
```

- [ ] **Step 3: Add `language` to `Item`**

In `ShoppingList/Models/Item.swift`, add the field to the struct:

```swift
struct Item: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var rawInput: String?
    var quantity: String?
    var category: String?
    var flagged: Bool = false
    var status: ItemStatus = .active
    var completedAt: Date?
    var completedBy: String?
    var addedBy: String
    var addedAt: Date
    var source: ItemSource = .text
    var language: String = "en"

    // ... existing computed properties unchanged
}
```

- [ ] **Step 4: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Models/User.swift ShoppingList/Models/ShoppingList.swift ShoppingList/Models/Item.swift
git commit -m "feat: add language fields to User, ShoppingList, and Item models"
```

---

### Task 2: LanguageService

**Files:**
- Create: `ShoppingList/Services/LanguageService.swift`

- [ ] **Step 1: Create LanguageService**

```swift
// ShoppingList/Services/LanguageService.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case da = "da"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .da: return "Dansk"
        }
    }
}

@MainActor
class LanguageService: ObservableObject {
    @Published var appLanguage: String?
    private let db = Firestore.firestore()

    /// The resolved locale for SwiftUI environment
    var resolvedLocale: Locale {
        Locale(identifier: resolvedAppLanguage)
    }

    /// Resolve the app-level language: user setting > device > fallback to English
    var resolvedAppLanguage: String {
        if let lang = appLanguage {
            return lang
        }
        return Self.deviceLanguage
    }

    /// Resolve language for a specific list: list override > app language
    func resolvedLanguage(for list: ShoppingList) -> String {
        if let listLang = list.language {
            return listLang
        }
        return resolvedAppLanguage
    }

    /// Device language: "da" if Danish, otherwise "en"
    static var deviceLanguage: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("da") ? "da" : "en"
    }

    /// Load the user's language preference from Firestore
    func loadLanguage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            let doc = try? await db.collection("users").document(userId).getDocument()
            if let data = doc?.data(),
               let settings = data["settings"] as? [String: Any] {
                self.appLanguage = settings["language"] as? String
            }
        }
    }

    /// Update the user's language preference in Firestore
    func updateAppLanguage(_ language: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(userId).updateData([
            "settings.language": language as Any
        ])
        appLanguage = language
    }

    /// Update a list's language override in Firestore
    func updateListLanguage(_ listId: String, language: String?) async throws {
        try await db.collection("lists").document(listId).updateData([
            "language": language as Any
        ])
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodegen generate && xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Services/LanguageService.swift
git commit -m "feat: add LanguageService for language resolution"
```

---

### Task 3: Wire LanguageService into App Root

**Files:**
- Modify: `ShoppingList/ShoppingListApp.swift`

- [ ] **Step 1: Add LanguageService and locale environment**

Replace the entire `ShoppingListApp.swift`:

```swift
import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var languageService = LanguageService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.background.ignoresSafeArea())
                } else if authService.isSignedIn {
                    ContentView()
                        .onAppear { languageService.loadLanguage() }
                } else {
                    SignInView()
                }
            }
            .environmentObject(authService)
            .environmentObject(languageService)
            .environment(\.locale, languageService.resolvedLocale)
            .onAppear {
                notificationService.requestPermission()
            }
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/ShoppingListApp.swift
git commit -m "feat: wire LanguageService into app root with locale environment"
```

---

### Task 4: String Catalog

**Files:**
- Create: `ShoppingList/Resources/Localizable.xcstrings`

This is the largest task. The String Catalog is a JSON file that Xcode uses for localization.

- [ ] **Step 1: Create the Localizable.xcstrings file**

Create the file at `ShoppingList/Resources/Localizable.xcstrings`. This is a JSON file. Due to its size (~80 strings), create it with all English and Danish translations.

The file format is:
```json
{
  "sourceLanguage": "en",
  "strings": {
    "Key": {
      "localizations": {
        "da": {
          "stringUnit": {
            "state": "translated",
            "value": "Danish translation"
          }
        }
      }
    }
  },
  "version": "1.0"
}
```

Create the full file with all strings. Key strings and their Danish translations:

**Tabs & Navigation:**
- "Lists" → "Lister"
- "Activity" → "Aktivitet"
- "Profile" → "Profil"
- "My Lists" → "Mine lister"
- "Activity" (nav) → "Aktivitet"

**List Management:**
- "List name" → "Listenavn"
- "New List" → "Ny liste"
- "Create List" → "Opret liste"
- "Cancel" → "Annuller"
- "Create" → "Opret"
- "No Lists Yet" → "Ingen lister endnu"
- "Tap + to create your first shopping list" → "Tryk + for at oprette din første indkøbsliste"

**List Detail & Items:**
- "Add items..." → "Tilføj varer..."
- "List Settings" → "Listeindstillinger"
- "Suggestions" → "Forslag"
- "Check Duplicates" → "Tjek dubletter"
- "Completed (%lld)" → "Fuldført (%lld)"

**Edit Item:**
- "Item" → "Vare"
- "Name" → "Navn"
- "Quantity (optional)" → "Antal (valgfrit)"
- "Category" → "Kategori"
- "Edit Item" → "Rediger vare"
- "Save" → "Gem"

**Profile & Settings:**
- "Account" → "Konto"
- "Preferences" → "Præferencer"
- "Notifications" → "Notifikationer"
- "Notification settings" → "Notifikationsindstillinger"
- "Sign Out" → "Log ud"
- "Language" → "Sprog"
- "Device Default" → "Enhedsstandard"
- "App Default" → "Appstandard"

**List Settings:**
- "List Name" → "Listenavn"
- "Members" → "Medlemmer"
- "Owner" → "Ejer"
- "Member" → "Medlem"
- "Invite Members" → "Inviter medlemmer"
- "Delete List" → "Slet liste"
- "Leave List" → "Forlad liste"
- "Done" → "Færdig"
- "Delete" → "Slet"
- "This will permanently delete the list for all members." → "Dette vil permanent slette listen for alle medlemmer."

**Invite:**
- "Invite to %@" → "Inviter til %@"
- "Share this link with family members so they can join your list" → "Del dette link med familiemedlemmer, så de kan deltage i din liste"
- "Share Invite Link" → "Del invitationslink"

**Activity:**
- "No Activity Yet" → "Ingen aktivitet endnu"
- "Activity will appear here as you use your lists more" → "Aktivitet vil vises her, efterhånden som du bruger dine lister mere"

**Suggestions:**
- "Finding suggestions..." → "Finder forslag..."
- "No Suggestions Yet" → "Ingen forslag endnu"
- "Suggestions improve as you use your lists more" → "Forslag forbedres, efterhånden som du bruger dine lister mere"
- "Frequently Bought" → "Ofte købt"

**Duplicates:**
- "No Duplicates Found" → "Ingen dubletter fundet"
- "Your list looks clean!" → "Din liste ser fin ud!"
- "suggested" → "foreslået"
- "Merge as \"%@\"" → "Flet som \"%@\""
- "Keep All" → "Behold alle"
- "Similar Items" → "Lignende varer"
- "Duplicate Review" → "Dubletgennemgang"

**Photo:**
- "I found these items" → "Jeg fandt disse varer"
- "Add from Photo" → "Tilføj fra foto"
- "Add %lld" → "Tilføj %lld"

**Auth:**
- "Shopping List" → "Indkøbsliste"
- "Keep your family's groceries in sync" → "Hold familiens indkøb synkroniseret"
- "Sign in with test account" → "Log ind med testkonto"

**Components:**
- "Offline — changes will sync when connected" → "Offline — ændringer synkroniseres når forbindelsen genoprettes"

**Categories (for per-list override):**
- "Produce" → "Frugt & grønt"
- "Dairy" → "Mejeri"
- "Meat" → "Kød"
- "Bakery" → "Bageri"
- "Frozen" → "Frost"
- "Beverages" → "Drikkevarer"
- "Snacks" → "Snacks"
- "Pantry" → "Kolonial"
- "Household" → "Husholdning"
- "Personal Care" → "Personlig pleje"
- "Other" → "Andet"

**Siri Intent dialogs:**
- "You need to open Shopping List and sign in first." → "Du skal åbne Indkøbsliste og logge ind først."
- "Sorry, I couldn't reach your lists. Try again in a moment." → "Beklager, jeg kunne ikke finde dine lister. Prøv igen om et øjeblik."
- "You don't have any shopping lists yet. Open the app to create one." → "Du har ingen indkøbslister endnu. Åbn appen for at oprette en."
- "Added %@ to %@." → "Tilføjede %@ til %@."
- "Sorry, I couldn't add that. Try again in a moment." → "Beklager, jeg kunne ikke tilføje det. Prøv igen om et øjeblik."
- "Sorry, something went wrong. Try again." → "Beklager, noget gik galt. Prøv igen."
- "Add to Shopping List" → "Tilføj til indkøbsliste"
- "Add items to a shopping list" → "Tilføj varer til en indkøbsliste"
- "Items" → "Varer"
- "List" → "Liste"

**Error messages:**
- "Unable to process Apple Sign-In credentials." → "Kunne ikke behandle Apple-loginoplysninger."
- "Failed to process image." → "Kunne ikke behandle billedet."
- "You must be signed in." → "Du skal være logget ind."
- "Invite link not found or expired." → "Invitationslink ikke fundet eller udløbet."
- "You're already a member of this list." → "Du er allerede medlem af denne liste."

Write the complete JSON file with all of these translations.

- [ ] **Step 2: Add the Resources directory to XcodeGen sources if needed**

Check `project.yml` — the `ShoppingList` target sources from `ShoppingList`, which includes `ShoppingList/Resources/` automatically since it's a subdirectory.

- [ ] **Step 3: Verify build**

```bash
xcodegen generate && xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/Resources/Localizable.xcstrings
git commit -m "feat: add String Catalog with English and Danish translations"
```

---

### Task 5: Category Localization

**Files:**
- Modify: `ShoppingList/Models/ItemCategory.swift`
- Modify: `ShoppingList/Views/ListDetail/CategorySectionView.swift`

- [ ] **Step 1: Add `localizedName(for:)` method to ItemCategory**

Add this method to `ItemCategory`:

```swift
enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    // ... existing cases unchanged

    var id: String { rawValue }

    /// Localized category name for a given language code.
    /// Used for per-list language override on category headers.
    func localizedName(for language: String) -> String {
        let locale = Locale(identifier: language)
        return String(localized: String.LocalizationValue(rawValue), locale: locale)
    }

    // ... existing emoji and sortOrder unchanged
}
```

- [ ] **Step 2: Update CategorySectionView to accept a language parameter**

Replace `CategorySectionView`:

```swift
import SwiftUI

struct CategorySectionView: View {
    let category: ItemCategory
    let items: [Item]
    let onToggleComplete: (Item) -> Void
    let onToggleFlag: (Item) -> Void
    let onDelete: (Item) -> Void
    var listLanguage: String? = nil

    @State private var isExpanded = true

    private var categoryDisplayName: String {
        if let lang = listLanguage {
            return "\(category.emoji) \(category.localizedName(for: lang))"
        }
        return "\(category.emoji) \(category.rawValue)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(categoryDisplayName)
                        .font(Theme.captionFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))

                    Spacer()

                    Text("\(items.count)")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.categoryTextColor(category.rawValue))
                }
                .padding(.horizontal, Theme.paddingMedium)
                .padding(.vertical, Theme.paddingSmall)
                .background(Theme.categoryColor(category.rawValue))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(items) { item in
                    ItemRowView(
                        item: item,
                        onToggleComplete: { onToggleComplete(item) },
                        onToggleFlag: { onToggleFlag(item) }
                    )
                }
            }
        }
    }
}
```

- [ ] **Step 3: Update ListDetailView to pass list language to CategorySectionView**

In `ShoppingList/Views/ListDetail/ListDetailView.swift`, add `@EnvironmentObject var languageService: LanguageService` and update the `CategorySectionView` call:

Add at the top of the struct:
```swift
@EnvironmentObject var languageService: LanguageService
```

Update the CategorySectionView instantiation (around line 33):
```swift
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
```

- [ ] **Step 4: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Models/ItemCategory.swift ShoppingList/Views/ListDetail/CategorySectionView.swift ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add localized category names with per-list language support"
```

---

### Task 6: Pass Language When Adding Items

**Files:**
- Modify: `ShoppingList/Services/ItemService.swift`
- Modify: `ShoppingList/Views/ListDetail/ListDetailView.swift`
- Modify: `ShoppingList/Intents/AddItemsIntent.swift`

- [ ] **Step 1: Add `language` parameter to `ItemService.addItem`**

In `ShoppingList/Services/ItemService.swift`, update the `addItem` method:

```swift
    func addItem(listId: String, rawInput: String, source: ItemSource = .text, language: String = "en") async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let item = Item(
            name: rawInput,
            rawInput: rawInput,
            addedBy: userId,
            addedAt: Date(),
            source: source,
            language: language
        )

        try db.collection("lists").document(listId)
            .collection("items")
            .addDocument(from: item)

        try await historyService.recordAction(
            listId: listId,
            itemName: rawInput,
            action: .added,
            userId: userId
        )

        try await db.collection("lists").document(listId).updateData([
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
```

Also update `addItemDirectly`:

```swift
    static func addItemDirectly(
        listId: String,
        rawInput: String,
        userId: String,
        source: ItemSource = .text,
        language: String = "en"
    ) async throws {
        let db = Firestore.firestore()

        let item = Item(
            name: rawInput,
            rawInput: rawInput,
            addedBy: userId,
            addedAt: Date(),
            source: source,
            language: language
        )

        try db.collection("lists").document(listId)
            .collection("items")
            .addDocument(from: item)

        let historyService = HistoryService()
        try await historyService.recordAction(
            listId: listId,
            itemName: rawInput,
            action: .added,
            userId: userId
        )

        try await db.collection("lists").document(listId).updateData([
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
```

- [ ] **Step 2: Pass language from ListDetailView when adding items**

In `ListDetailView.swift`, update all `addItem` calls to include the resolved language. The `languageService` is already injected from Task 5. Add a computed property:

```swift
    private var listLanguage: String {
        languageService.resolvedLanguage(for: list)
    }
```

Then update the three places items are added:

Text input (onSubmit):
```swift
Task { try? await itemService.addItem(listId: list.id ?? "", rawInput: text, language: listLanguage) }
```

Voice input (onMicTap):
```swift
Task {
    try? await itemService.addItem(listId: list.id ?? "", rawInput: text, source: .voice, language: listLanguage)
}
```

Photo confirm (onConfirm):
```swift
try? await itemService.addItem(
    listId: list.id ?? "",
    rawInput: item.name,
    source: .photo,
    language: listLanguage
)
```

Suggestions sheet:
```swift
SuggestionsView(listId: list.id ?? "") { item in
    Task { try? await itemService.addItem(listId: list.id ?? "", rawInput: item, language: listLanguage) }
}
```

- [ ] **Step 3: Pass language from AddItemsIntent**

In `ShoppingList/Intents/AddItemsIntent.swift`, resolve the language and pass it to `addItemDirectly`. After resolving the target list (around line 99), add:

```swift
        let language = targetList.language ?? {
            if let defaultId = try? await ListService.fetchUserDefaultListId(for: userId) {
                // Fetch user's language setting
                let db = Firestore.firestore()
                let userDoc = try? await db.collection("users").document(userId).getDocument()
                if let settings = userDoc?.data()?["settings"] as? [String: Any],
                   let lang = settings["language"] as? String {
                    return lang
                }
            }
            return LanguageService.deviceLanguage
        }()
```

Then update the `addItemDirectly` call:
```swift
            try await ItemService.addItemDirectly(
                listId: listId,
                rawInput: itemText,
                userId: userId,
                source: .voice,
                language: language
            )
```

- [ ] **Step 4: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Services/ItemService.swift ShoppingList/Views/ListDetail/ListDetailView.swift ShoppingList/Intents/AddItemsIntent.swift
git commit -m "feat: pass resolved language when adding items"
```

---

### Task 7: Settings UI — Language Pickers

**Files:**
- Modify: `ShoppingList/Views/Settings/ProfileView.swift`
- Modify: `ShoppingList/Views/Settings/ListSettingsView.swift`

- [ ] **Step 1: Add language picker to ProfileView**

Replace `ShoppingList/Views/Settings/ProfileView.swift`:

```swift
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var languageService: LanguageService

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.secondaryGreen)

                        VStack(alignment: .leading) {
                            Text(authService.user?.displayName ?? "User")
                                .font(Theme.headlineFont)
                            Text(authService.user?.email ?? "")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(String(localized: "Preferences")) {
                    Picker(String(localized: "Language"), selection: Binding(
                        get: { languageService.appLanguage ?? "__device__" },
                        set: { newValue in
                            let lang: String? = newValue == "__device__" ? nil : newValue
                            Task { try? await languageService.updateAppLanguage(lang) }
                        }
                    )) {
                        Text(String(localized: "Device Default")).tag("__device__")
                        Text("English").tag("en")
                        Text("Dansk").tag("da")
                    }

                    NavigationLink {
                        Text(String(localized: "Notification settings"))
                    } label: {
                        Label(String(localized: "Notifications"), systemImage: "bell")
                    }
                }

                Section {
                    Button(String(localized: "Sign Out"), role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle(String(localized: "Profile"))
        }
    }
}
```

- [ ] **Step 2: Add per-list language picker to ListSettingsView**

In `ShoppingList/Views/Settings/ListSettingsView.swift`, add `@EnvironmentObject var languageService: LanguageService` and a `@State` variable for the list language. Then add a language picker section.

Add to the struct properties:
```swift
    @EnvironmentObject var languageService: LanguageService
    @State private var listLanguage: String
```

Update `init`:
```swift
    init(list: ShoppingList) {
        self.list = list
        self._name = State(initialValue: list.name)
        self._listLanguage = State(initialValue: list.language ?? "__app__")
    }
```

Add a new Section after the "List Name" section:

```swift
                Section(String(localized: "Language")) {
                    Picker(String(localized: "Language"), selection: $listLanguage) {
                        Text(String(localized: "App Default")).tag("__app__")
                        Text("English").tag("en")
                        Text("Dansk").tag("da")
                    }
                    .onChange(of: listLanguage) { _, newValue in
                        let lang: String? = newValue == "__app__" ? nil : newValue
                        Task { try? await languageService.updateListLanguage(list.id ?? "", language: lang) }
                    }
                }
```

- [ ] **Step 3: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/Views/Settings/ProfileView.swift ShoppingList/Views/Settings/ListSettingsView.swift
git commit -m "feat: add language pickers to Profile and List Settings"
```

---

### Task 8: Localize All View Strings

**Files:**
- Modify: ~20 view files to replace hardcoded strings with `String(localized:)` or use SwiftUI's automatic `LocalizedStringKey` resolution

SwiftUI `Text("string literal")` already resolves against the String Catalog automatically when a `Localizable.xcstrings` file exists. However, strings in `Section("header")`, `Button("label")`, `Label("text", ...)`, `.navigationTitle("title")`, `TextField("placeholder", ...)`, and `ContentUnavailableView("title", ...)` also resolve automatically because they accept `LocalizedStringKey`.

**This means most strings require NO code changes** — SwiftUI automatically looks up the key in the String Catalog.

The exceptions that DO need changes:
- String interpolations that aren't in `Text()` (e.g., inline string construction)
- Error descriptions in `LocalizedError` conformances
- Strings passed to non-SwiftUI APIs

- [ ] **Step 1: Update error descriptions in AuthService**

In `ShoppingList/Services/AuthService.swift`, update `AuthError`:

```swift
enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return String(localized: "Unable to process Apple Sign-In credentials.")
        }
    }
}
```

- [ ] **Step 2: Update error descriptions in ListService**

In `ShoppingList/Services/ListService.swift`, update `ListServiceError`:

```swift
enum ListServiceError: LocalizedError {
    case notAuthenticated
    case inviteNotFound
    case alreadyMember

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return String(localized: "You must be signed in.")
        case .inviteNotFound: return String(localized: "Invite link not found or expired.")
        case .alreadyMember: return String(localized: "You're already a member of this list.")
        }
    }
}
```

- [ ] **Step 3: Update PhotoService error**

In `ShoppingList/Services/PhotoService.swift`, update the error description to use `String(localized:)`.

- [ ] **Step 4: Verify build**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Services/AuthService.swift ShoppingList/Services/ListService.swift ShoppingList/Services/PhotoService.swift
git commit -m "feat: localize error descriptions for Danish support"
```

---

### Task 9: Cloud Function — Language-Aware Parsing

**Files:**
- Modify: `functions/src/parseInput.ts`

- [ ] **Step 1: Update `parseRawInput` to accept a language parameter**

In `functions/src/parseInput.ts`, update the function:

```typescript
export async function parseRawInput(rawInput: string, language: string = "en"): Promise<ParsedItem[]> {
  const model = getModel();

  const languageName = language === "da" ? "Danish" : "English";

  const prompt = `Parse this shopping list input into individual items. The text is written in ${languageName}.
For each item, extract:
- name: the item name (clean, capitalized, in the original language)
- quantity: amount if mentioned (e.g., "2 lbs", "1 dozen"), or null
- category: one of [${CATEGORIES.join(", ")}] (always use English category names)

Input: "${rawInput}"

Respond with ONLY valid JSON: {"items": [{"name": "...", "quantity": "..." or null, "category": "..."}]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return [{ name: rawInput, quantity: null, category: null }];
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.items || [{ name: rawInput, quantity: null, category: null }];
  } catch {
    return [{ name: rawInput, quantity: null, category: null }];
  }
}
```

- [ ] **Step 2: Update `onItemCreated` to read the item's language**

In the same file, update the trigger handler to pass the language:

```typescript
export const onItemCreated = onDocumentCreated(
  {
    document: "lists/{listId}/items/{itemId}",
    secrets: [geminiApiKey],
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const rawInput = data.rawInput;
    if (!rawInput) return;

    if (data.category) return;

    const listId = event.params.listId;
    const language = data.language || "en";

    try {
      const parsedItems = await parseRawInput(rawInput, language);

      if (parsedItems.length === 1) {
        const item = parsedItems[0];
        await snapshot.ref.update({
          name: item.name,
          quantity: item.quantity || null,
          category: item.category || "Other",
        });
      } else {
        const batch = db.batch();
        const itemsRef = db.collection("lists").doc(listId).collection("items");

        for (const item of parsedItems) {
          const newRef = itemsRef.doc();
          batch.set(newRef, {
            name: item.name,
            rawInput: rawInput,
            quantity: item.quantity || null,
            category: item.category || "Other",
            flagged: false,
            status: "active",
            addedBy: data.addedBy,
            addedAt: data.addedAt,
            source: data.source,
            language: language,
          });
        }

        batch.delete(snapshot.ref);
        await batch.commit();
      }
    } catch (error) {
      console.error("Parse failed, item will remain as-is:", error);
    }
  }
);
```

- [ ] **Step 3: Build Cloud Functions**

```bash
cd functions && npm run build
```
Expected: No TypeScript errors

- [ ] **Step 4: Deploy Cloud Functions**

```bash
cd functions && npm run deploy
```

- [ ] **Step 5: Commit**

```bash
git add functions/src/parseInput.ts
git commit -m "feat: language-aware item parsing in Cloud Function"
```

---

### Task 10: Regenerate Project & Full Verification

**Files:**
- No new files — regenerate and verify

- [ ] **Step 1: Regenerate Xcode project**

```bash
xcodegen generate
```

- [ ] **Step 2: Full build verification**

```bash
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Run UI tests**

```bash
xcodebuild build-for-testing -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -3
xcodebuild test-without-building -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListUITests 2>&1 | grep -E "Test Case|passed|failed"
```
Expected: All 4 tests pass

- [ ] **Step 4: Commit if project file changed**

```bash
git add ShoppingList.xcodeproj/ project.yml
git commit -m "chore: regenerate Xcode project with localization resources"
```

---

## Summary

| Task | What it builds |
|------|----------------|
| 1. Data model changes | `language` fields on User, ShoppingList, Item |
| 2. LanguageService | Language resolution logic (list > app > device) |
| 3. App root wiring | `.environment(\.locale)` + LanguageService injection |
| 4. String Catalog | ~80 strings translated to Danish |
| 5. Category localization | `localizedName(for:)` + per-list category headers |
| 6. Item language passing | All add-item paths include resolved language |
| 7. Settings UI | Language pickers in Profile and List Settings |
| 8. View string localization | Error descriptions use `String(localized:)` |
| 9. Cloud Function | Language-aware Gemini prompt for item parsing |
| 10. Final verification | Build + UI tests + project regeneration |
