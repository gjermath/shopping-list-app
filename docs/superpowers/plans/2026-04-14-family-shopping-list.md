# Family Shopping List App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS family shopping list app with real-time collaboration, AI-powered item parsing/categorization/suggestions, and Firebase backend.

**Architecture:** SwiftUI app with Firebase (Auth, Firestore, Cloud Functions, Storage, FCM, Dynamic Links). AI features run in Cloud Functions calling Gemini Flash. On-device Apple Speech for voice transcription. Offline-first with Firestore persistence.

**Tech Stack:** Swift/SwiftUI, Firebase iOS SDK, Firebase Cloud Functions (TypeScript), Google Cloud Gemini Flash API, Apple Speech framework, WidgetKit

---

## File Structure

```
ShoppingList/                              # Xcode project root
├── ShoppingList/
│   ├── ShoppingListApp.swift              # App entry, Firebase init, auth gate
│   ├── ContentView.swift                  # Root tab bar (Lists, Activity, Profile)
│   ├── GoogleService-Info.plist           # Firebase config (from Firebase Console)
│   │
│   ├── Theme/
│   │   └── SoftSageTheme.swift            # Colors, fonts, spacing constants
│   │
│   ├── Models/
│   │   ├── User.swift                     # User profile model (Codable + Firestore)
│   │   ├── ShoppingList.swift             # List model with memberIds, inviteCode
│   │   ├── Item.swift                     # Item model with status, category, flag
│   │   ├── HistoryEntry.swift             # History action log model
│   │   └── ItemCategory.swift             # Category enum with display properties
│   │
│   ├── Services/
│   │   ├── AuthService.swift              # Apple Sign-In + Firebase Auth, session state
│   │   ├── ListService.swift              # List CRUD, membership, Firestore listeners
│   │   ├── ItemService.swift              # Item CRUD, check-off, flag toggle, listeners
│   │   ├── HistoryService.swift           # Write/query history entries
│   │   ├── AIService.swift                # Calls Cloud Functions (parse, suggest, duplicates)
│   │   ├── SpeechService.swift            # Apple Speech on-device transcription
│   │   ├── PhotoService.swift             # Camera capture + Firebase Storage upload
│   │   ├── InviteService.swift            # Dynamic Link generation + handling
│   │   └── NotificationService.swift      # FCM registration, permission, token management
│   │
│   ├── Views/
│   │   ├── Auth/
│   │   │   └── SignInView.swift           # Apple Sign-In button, onboarding
│   │   │
│   │   ├── Lists/
│   │   │   ├── ListsTabView.swift         # Home tab — all user's lists
│   │   │   ├── ListCardView.swift         # Single list card (name, count, avatars)
│   │   │   └── CreateListView.swift       # Sheet to name + create a new list
│   │   │
│   │   ├── ListDetail/
│   │   │   ├── ListDetailView.swift       # Main list screen — categories, items, input
│   │   │   ├── CategorySectionView.swift  # Collapsible category header + items
│   │   │   ├── ItemRowView.swift          # Single item row (star, name, qty, avatar)
│   │   │   ├── InputBarView.swift         # Bottom input bar (text, mic, camera)
│   │   │   ├── CompletedSectionView.swift # Collapsed completed items at bottom
│   │   │   └── EditItemView.swift         # Edit item sheet (name, qty, category)
│   │   │
│   │   ├── Activity/
│   │   │   ├── ActivityTabView.swift      # History feed with filters
│   │   │   └── ActivityRowView.swift      # Single history entry row
│   │   │
│   │   ├── Suggestions/
│   │   │   └── SuggestionsView.swift      # AI-suggested frequent items
│   │   │
│   │   ├── Duplicates/
│   │   │   └── DuplicateReviewView.swift  # Grouped duplicate items with merge/keep
│   │   │
│   │   ├── Settings/
│   │   │   ├── ListSettingsView.swift     # List rename, members, delete
│   │   │   ├── InviteView.swift           # Generate + share invite link
│   │   │   └── ProfileView.swift          # Account info, notifications, default list
│   │   │
│   │   ├── Photo/
│   │   │   └── PhotoConfirmationView.swift # Review extracted items before adding
│   │   │
│   │   └── Components/
│   │       ├── FlagToggle.swift           # Star/flag button component
│   │       ├── OfflineBanner.swift        # "Offline" connectivity banner
│   │       └── MemberAvatarStack.swift    # Overlapping member profile photos
│   │
│   └── Utilities/
│       ├── NetworkMonitor.swift           # NWPathMonitor wrapper for connectivity
│       └── Date+Extensions.swift          # Relative time formatting
│
├── ShoppingListTests/
│   ├── Models/
│   │   ├── ItemTests.swift
│   │   ├── ShoppingListTests.swift
│   │   └── ItemCategoryTests.swift
│   ├── Services/
│   │   ├── ItemServiceTests.swift
│   │   ├── ListServiceTests.swift
│   │   └── HistoryServiceTests.swift
│   └── Views/
│       └── (UI tests via Xcode previews + snapshot testing)
│
├── ShoppingListWidget/
│   ├── ShoppingListWidget.swift           # Widget entry point + timeline provider
│   └── WidgetViews.swift                  # Small + medium widget layouts
│
functions/                                  # Firebase Cloud Functions (TypeScript)
├── package.json
├── tsconfig.json
├── .eslintrc.js
├── src/
│   ├── index.ts                           # Export all functions
│   ├── parseInput.ts                      # Firestore-triggered NLP parsing
│   ├── parseImage.ts                      # HTTPS-callable image extraction
│   ├── categorize.ts                      # Item categorization
│   ├── suggestFrequent.ts                 # HTTPS-callable frequency suggestions
│   ├── reviewDuplicates.ts                # HTTPS-callable duplicate detection
│   ├── notifications.ts                   # FCM notification triggers
│   └── gemini.ts                          # Shared Gemini Flash client + prompts
├── test/
│   ├── parseInput.test.ts
│   ├── parseImage.test.ts
│   ├── categorize.test.ts
│   ├── suggestFrequent.test.ts
│   └── reviewDuplicates.test.ts
│
├── firebase.json                          # Firebase project config
├── firestore.rules                        # Security rules
├── firestore.indexes.json                 # Composite indexes
└── .firebaserc                            # Project alias
```

---

## Phase 1: Project Foundation

### Task 1: Create Xcode Project & Firebase Setup

**Files:**
- Create: `ShoppingList/` (Xcode project via `xcodebuild` or Xcode GUI)
- Create: `ShoppingList/ShoppingList/GoogleService-Info.plist` (from Firebase Console)
- Create: `firebase.json`
- Create: `.firebaserc`
- Create: `firestore.rules`
- Create: `firestore.indexes.json`
- Create: `.gitignore`

- [ ] **Step 1: Create the Xcode project**

Open Xcode and create a new project:
- Template: App
- Product Name: `ShoppingList`
- Team: your Apple Developer account
- Organization Identifier: your reverse-domain (e.g. `com.yourname`)
- Interface: SwiftUI
- Language: Swift
- Include Tests: Yes (Unit Tests checked)
- Storage: None

Save to `/Users/tgjerm01/Programming/shopping-list-app/`

- [ ] **Step 2: Create the Firebase project**

1. Go to https://console.firebase.google.com
2. Create new project "ShoppingList" (or your preferred name)
3. Enable Google Analytics (optional)
4. Add iOS app with your bundle identifier
5. Download `GoogleService-Info.plist` and add it to `ShoppingList/ShoppingList/`
6. In Firebase Console, enable:
   - Authentication → Sign-in method → Apple
   - Cloud Firestore → Create database (start in test mode, we'll add rules later)
   - Storage → Get started
   - Cloud Messaging (enabled by default)

- [ ] **Step 3: Add Firebase SDK via Swift Package Manager**

In Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select these libraries:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFirestoreSwift
   - FirebaseFunctions
   - FirebaseStorage
   - FirebaseMessaging
   - FirebaseDynamicLinks

- [ ] **Step 4: Initialize Firebase in the app entry point**

```swift
// ShoppingList/ShoppingList/ShoppingListApp.swift
import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 5: Create Firebase project config files**

```json
// firebase.json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

```
// .firebaserc
{
  "projects": {
    "default": "YOUR_FIREBASE_PROJECT_ID"
  }
}
```

- [ ] **Step 6: Write Firestore security rules**

```
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: read/write own document only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Lists: read/write if you're a member
    match /lists/{listId} {
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow delete: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;

      // Items: same as parent list
      match /items/{itemId} {
        allow read, write: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/lists/$(listId)).data.memberIds;
      }

      // History: members can read, system writes via Cloud Functions
      match /history/{historyId} {
        allow read: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/lists/$(listId)).data.memberIds;
        allow create: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/lists/$(listId)).data.memberIds;
      }
    }
  }
}
```

- [ ] **Step 7: Create initial Firestore indexes**

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "addedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "history",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

- [ ] **Step 8: Create .gitignore**

```
// .gitignore
# Xcode
*.xcodeproj/project.xcworkspace/
*.xcodeproj/xcuserdata/
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
build/

# Firebase
.firebase/
functions/node_modules/
functions/lib/

# Secrets
GoogleService-Info.plist
.firebaserc

# Misc
.DS_Store
*.swp
.superpowers/
```

- [ ] **Step 9: Commit**

```bash
git add .gitignore firebase.json firestore.rules firestore.indexes.json
git add ShoppingList/
git commit -m "feat: scaffold Xcode project with Firebase SDK integration"
```

---

### Task 2: Design System — Soft Sage Theme

**Files:**
- Create: `ShoppingList/ShoppingList/Theme/SoftSageTheme.swift`

- [ ] **Step 1: Write the theme file**

```swift
// ShoppingList/ShoppingList/Theme/SoftSageTheme.swift
import SwiftUI

enum Theme {
    // MARK: - Colors

    static let background = Color(red: 0.98, green: 0.99, blue: 0.976)       // #FAFDF9
    static let primaryGreen = Color(red: 0.18, green: 0.49, blue: 0.196)     // #2E7D32
    static let secondaryGreen = Color(red: 0.506, green: 0.78, blue: 0.518)  // #81C784
    static let flagAmber = Color(red: 1.0, green: 0.702, blue: 0.0)          // #FFB300
    static let surfaceWhite = Color.white
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)       // #212121
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)        // #999999
    static let divider = Color(red: 0.93, green: 0.93, blue: 0.93)           // #EDEDED

    // MARK: - Category Colors

    static func categoryColor(_ category: String) -> Color {
        switch category {
        case "Produce":       return Color(red: 0.945, green: 0.973, blue: 0.914) // #F1F8E9
        case "Dairy":         return Color(red: 0.89, green: 0.949, blue: 0.992)  // #E3F2FD
        case "Meat":          return Color(red: 0.988, green: 0.894, blue: 0.882) // #FCE4E2
        case "Bakery":        return Color(red: 1.0, green: 0.953, blue: 0.878)   // #FFF3E0
        case "Frozen":        return Color(red: 0.882, green: 0.961, blue: 0.996) // #E1F5FE
        case "Beverages":     return Color(red: 0.914, green: 0.906, blue: 0.965) // #E9E7F6
        case "Snacks":        return Color(red: 1.0, green: 0.965, blue: 0.886)   // #FFF6E2
        case "Pantry":        return Color(red: 0.937, green: 0.922, blue: 0.882) // #EFEBE1
        case "Household":     return Color(red: 0.914, green: 0.941, blue: 0.945) // #E9F0F2
        case "Personal Care": return Color(red: 0.969, green: 0.914, blue: 0.957) // #F7E9F4
        default:              return Color(red: 0.961, green: 0.961, blue: 0.961) // #F5F5F5 (Other)
        }
    }

    static func categoryTextColor(_ category: String) -> Color {
        switch category {
        case "Produce":       return Color(red: 0.337, green: 0.545, blue: 0.184) // #558B2F
        case "Dairy":         return Color(red: 0.082, green: 0.396, blue: 0.753) // #1565C0
        case "Meat":          return Color(red: 0.776, green: 0.157, blue: 0.157) // #C62828
        case "Bakery":        return Color(red: 0.929, green: 0.424, blue: 0.0)   // #EF6C00
        case "Frozen":        return Color(red: 0.012, green: 0.388, blue: 0.616) // #0363B8
        case "Beverages":     return Color(red: 0.369, green: 0.208, blue: 0.694) // #5E35B1
        case "Snacks":        return Color(red: 0.698, green: 0.494, blue: 0.0)   // #B27E00
        case "Pantry":        return Color(red: 0.427, green: 0.349, blue: 0.196) // #6D5932
        case "Household":     return Color(red: 0.263, green: 0.388, blue: 0.424) // #43636C
        case "Personal Care": return Color(red: 0.533, green: 0.176, blue: 0.455) // #882D74
        default:              return Color(red: 0.459, green: 0.459, blue: 0.459) // #757575
        }
    }

    // MARK: - Typography

    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Spacing

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 14
    static let cardShadow: CGFloat = 4
}
```

- [ ] **Step 2: Verify it compiles**

Build the project in Xcode (Cmd+B). Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/ShoppingList/Theme/SoftSageTheme.swift
git commit -m "feat: add Soft Sage design system with colors, typography, spacing"
```

---

### Task 3: Data Models

**Files:**
- Create: `ShoppingList/ShoppingList/Models/ItemCategory.swift`
- Create: `ShoppingList/ShoppingList/Models/User.swift`
- Create: `ShoppingList/ShoppingList/Models/ShoppingList.swift`
- Create: `ShoppingList/ShoppingList/Models/Item.swift`
- Create: `ShoppingList/ShoppingList/Models/HistoryEntry.swift`
- Create: `ShoppingList/ShoppingListTests/Models/ItemTests.swift`
- Create: `ShoppingList/ShoppingListTests/Models/ShoppingListTests.swift`
- Create: `ShoppingList/ShoppingListTests/Models/ItemCategoryTests.swift`

- [ ] **Step 1: Write ItemCategory enum**

```swift
// ShoppingList/ShoppingList/Models/ItemCategory.swift
import Foundation

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case bakery = "Bakery"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case pantry = "Pantry"
    case household = "Household"
    case personalCare = "Personal Care"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .produce:      return "🥬"
        case .dairy:        return "🥛"
        case .meat:         return "🥩"
        case .bakery:       return "🍞"
        case .frozen:       return "🧊"
        case .beverages:    return "🥤"
        case .snacks:       return "🍪"
        case .pantry:       return "🫙"
        case .household:    return "🧹"
        case .personalCare: return "🧴"
        case .other:        return "📦"
        }
    }

    var sortOrder: Int {
        switch self {
        case .produce: return 0
        case .dairy: return 1
        case .meat: return 2
        case .bakery: return 3
        case .frozen: return 4
        case .beverages: return 5
        case .snacks: return 6
        case .pantry: return 7
        case .household: return 8
        case .personalCare: return 9
        case .other: return 10
        }
    }
}
```

- [ ] **Step 2: Write ItemCategory tests**

```swift
// ShoppingList/ShoppingListTests/Models/ItemCategoryTests.swift
import XCTest
@testable import ShoppingList

final class ItemCategoryTests: XCTestCase {
    func testAllCasesHaveEmoji() {
        for category in ItemCategory.allCases {
            XCTAssertFalse(category.emoji.isEmpty, "\(category.rawValue) missing emoji")
        }
    }

    func testAllCasesHaveUniqueSortOrder() {
        let orders = ItemCategory.allCases.map(\.sortOrder)
        XCTAssertEqual(orders.count, Set(orders).count, "Sort orders must be unique")
    }

    func testRawValuesMatchDisplayStrings() {
        XCTAssertEqual(ItemCategory.produce.rawValue, "Produce")
        XCTAssertEqual(ItemCategory.personalCare.rawValue, "Personal Care")
        XCTAssertEqual(ItemCategory.other.rawValue, "Other")
    }

    func testCodableRoundTrip() throws {
        let original = ItemCategory.dairy
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ItemCategory.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
```

- [ ] **Step 3: Run tests to verify they pass**

Run: Cmd+U in Xcode, or:
```bash
xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```
Expected: All tests PASS.

- [ ] **Step 4: Write User model**

```swift
// ShoppingList/ShoppingList/Models/User.swift
import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var photoURL: String?
    var createdAt: Date
    var lastActiveAt: Date
    var defaultListId: String?
    var settings: UserSettings

    struct UserSettings: Codable {
        var notificationsEnabled: Bool = true
    }
}
```

- [ ] **Step 5: Write ShoppingList model**

```swift
// ShoppingList/ShoppingList/Models/ShoppingList.swift
import Foundation
import FirebaseFirestore

struct ShoppingList: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var inviteCode: String

    var isMember: Bool {
        guard let userId = currentUserId else { return false }
        return memberIds.contains(userId)
    }

    // Injected at decode time or set manually — not persisted
    var currentUserId: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, ownerId, memberIds, createdAt, updatedAt, inviteCode
    }
}
```

- [ ] **Step 6: Write Item model**

```swift
// ShoppingList/ShoppingList/Models/Item.swift
import Foundation
import FirebaseFirestore

enum ItemStatus: String, Codable {
    case active
    case completed
}

enum ItemSource: String, Codable {
    case text
    case voice
    case photo
}

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

    var isCompleted: Bool { status == .completed }

    var resolvedCategory: ItemCategory {
        guard let category = category,
              let parsed = ItemCategory(rawValue: category) else {
            return .other
        }
        return parsed
    }
}
```

- [ ] **Step 7: Write HistoryEntry model**

```swift
// ShoppingList/ShoppingList/Models/HistoryEntry.swift
import Foundation
import FirebaseFirestore

enum HistoryAction: String, Codable {
    case added
    case completed
    case removed
    case reAdded = "re-added"
}

struct HistoryEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var itemName: String
    var category: String?
    var action: HistoryAction
    var userId: String
    var timestamp: Date
    var purchaseCount: Int = 0
}
```

- [ ] **Step 8: Write model tests**

```swift
// ShoppingList/ShoppingListTests/Models/ItemTests.swift
import XCTest
@testable import ShoppingList

final class ItemTests: XCTestCase {
    func testNewItemDefaultsToActive() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.status, .active)
        XCTAssertFalse(item.isCompleted)
    }

    func testNewItemDefaultsToUnflagged() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertFalse(item.flagged)
    }

    func testResolvedCategoryParsesValidCategory() {
        let item = Item(name: "Milk", category: "Dairy", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .dairy)
    }

    func testResolvedCategoryFallsBackToOther() {
        let item = Item(name: "Stuff", category: "Unknown", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .other)
    }

    func testResolvedCategoryNilIsOther() {
        let item = Item(name: "Stuff", category: nil, addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.resolvedCategory, .other)
    }

    func testCompletedItemReportsIsCompleted() {
        var item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        item.status = .completed
        XCTAssertTrue(item.isCompleted)
    }

    func testDefaultSourceIsText() {
        let item = Item(name: "Milk", addedBy: "user1", addedAt: Date())
        XCTAssertEqual(item.source, .text)
    }
}
```

```swift
// ShoppingList/ShoppingListTests/Models/ShoppingListTests.swift
import XCTest
@testable import ShoppingList

final class ShoppingListTests: XCTestCase {
    func testIsMemberReturnsTrueForMember() {
        var list = ShoppingList(
            name: "Groceries",
            ownerId: "owner1",
            memberIds: ["owner1", "user2"],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: "abc123"
        )
        list.currentUserId = "user2"
        XCTAssertTrue(list.isMember)
    }

    func testIsMemberReturnsFalseForNonMember() {
        var list = ShoppingList(
            name: "Groceries",
            ownerId: "owner1",
            memberIds: ["owner1"],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: "abc123"
        )
        list.currentUserId = "stranger"
        XCTAssertFalse(list.isMember)
    }
}
```

- [ ] **Step 9: Run all tests**

Run: Cmd+U in Xcode.
Expected: All tests PASS.

- [ ] **Step 10: Commit**

```bash
git add ShoppingList/ShoppingList/Models/ ShoppingList/ShoppingListTests/Models/
git commit -m "feat: add data models for User, ShoppingList, Item, HistoryEntry, ItemCategory"
```

---

## Phase 2: Authentication & Core Services

### Task 4: Authentication Service — Apple Sign-In

**Files:**
- Create: `ShoppingList/ShoppingList/Services/AuthService.swift`
- Create: `ShoppingList/ShoppingList/Views/Auth/SignInView.swift`
- Modify: `ShoppingList/ShoppingList/ShoppingListApp.swift`

- [ ] **Step 1: Enable Sign in with Apple capability**

In Xcode:
1. Select the ShoppingList target → Signing & Capabilities
2. Click "+ Capability" → add "Sign in with Apple"

- [ ] **Step 2: Write AuthService**

```swift
// ShoppingList/ShoppingList/Services/AuthService.swift
import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = true

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoading = false
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    var isSignedIn: Bool { user != nil }

    // MARK: - Apple Sign-In

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce else {
                throw AuthError.invalidCredential
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            try await createUserDocumentIfNeeded(authResult.user)

        case .failure(let error):
            throw error
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - User Document

    private func createUserDocumentIfNeeded(_ user: FirebaseAuth.User) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.uid)
        let doc = try await docRef.getDocument()

        if !doc.exists {
            let appUser = AppUser(
                displayName: user.displayName ?? "User",
                email: user.email ?? "",
                photoURL: user.photoURL?.absoluteString,
                createdAt: Date(),
                lastActiveAt: Date(),
                settings: AppUser.UserSettings()
            )
            try docRef.setData(from: appUser)
        } else {
            try await docRef.updateData(["lastActiveAt": FieldValue.serverTimestamp()])
        }
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                precondition(status == errSecSuccess)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Unable to process Apple Sign-In credentials."
        }
    }
}
```

- [ ] **Step 3: Write SignInView**

```swift
// ShoppingList/ShoppingList/Views/Auth/SignInView.swift
import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            Spacer()

            VStack(spacing: Theme.paddingSmall) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.primaryGreen)

                Text("Shopping List")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)

                Text("Keep your family's groceries in sync")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                authService.handleSignInWithAppleRequest(request)
            } onCompletion: { result in
                Task {
                    do {
                        try await authService.handleSignInWithAppleCompletion(result)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(Theme.cornerRadius)
            .padding(.horizontal, Theme.paddingLarge)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.captionFont)
                    .foregroundColor(.red)
            }

            Spacer()
                .frame(height: 40)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
```

- [ ] **Step 4: Update app entry point with auth gate**

```swift
// ShoppingList/ShoppingList/ShoppingListApp.swift
import SwiftUI
import FirebaseCore

@main
struct ShoppingListApp: App {
    @StateObject private var authService = AuthService()

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
                } else {
                    SignInView()
                }
            }
            .environmentObject(authService)
        }
    }
}
```

- [ ] **Step 5: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 6: Commit**

```bash
git add ShoppingList/ShoppingList/Services/AuthService.swift
git add ShoppingList/ShoppingList/Views/Auth/SignInView.swift
git add ShoppingList/ShoppingList/ShoppingListApp.swift
git commit -m "feat: add Apple Sign-In authentication with Firebase Auth"
```

---

### Task 5: Utility Services — Network Monitor & Date Extensions

**Files:**
- Create: `ShoppingList/ShoppingList/Utilities/NetworkMonitor.swift`
- Create: `ShoppingList/ShoppingList/Utilities/Date+Extensions.swift`
- Create: `ShoppingList/ShoppingList/Views/Components/OfflineBanner.swift`

- [ ] **Step 1: Write NetworkMonitor**

```swift
// ShoppingList/ShoppingList/Utilities/NetworkMonitor.swift
import Foundation
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
```

- [ ] **Step 2: Write Date extensions**

```swift
// ShoppingList/ShoppingList/Utilities/Date+Extensions.swift
import Foundation

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var isOlderThan24Hours: Bool {
        timeIntervalSinceNow < -86400
    }
}
```

- [ ] **Step 3: Write OfflineBanner**

```swift
// ShoppingList/ShoppingList/Views/Components/OfflineBanner.swift
import SwiftUI

struct OfflineBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: Theme.paddingSmall) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("Offline — changes will sync when connected")
                    .font(Theme.captionFont)
            }
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, Theme.paddingMedium)
            .frame(maxWidth: .infinity)
            .background(Theme.textSecondary)
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/ShoppingList/Utilities/ ShoppingList/ShoppingList/Views/Components/OfflineBanner.swift
git commit -m "feat: add network monitor, date extensions, offline banner"
```

---

### Task 6: List Service — CRUD & Real-Time Listeners

**Files:**
- Create: `ShoppingList/ShoppingList/Services/ListService.swift`

- [ ] **Step 1: Write ListService**

```swift
// ShoppingList/ShoppingList/Services/ListService.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ListService: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var isLoading = true

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("lists")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.lists = documents.compactMap { doc in
                    var list = try? doc.data(as: ShoppingList.self)
                    list?.currentUserId = userId
                    return list
                }
                self?.isLoading = false
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func createList(name: String) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ListServiceError.notAuthenticated
        }

        let inviteCode = UUID().uuidString.prefix(8).lowercased()
        let list = ShoppingList(
            name: name,
            ownerId: userId,
            memberIds: [userId],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: String(inviteCode)
        )

        let docRef = try db.collection("lists").addDocument(from: list)
        return docRef.documentID
    }

    func updateListName(_ listId: String, name: String) async throws {
        try await db.collection("lists").document(listId).updateData([
            "name": name,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func deleteList(_ listId: String) async throws {
        try await db.collection("lists").document(listId).delete()
    }

    func leaveList(_ listId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("lists").document(listId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }

    func joinList(inviteCode: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let snapshot = try await db.collection("lists")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            throw ListServiceError.inviteNotFound
        }

        let existingMembers = doc.data()["memberIds"] as? [String] ?? []
        if existingMembers.contains(userId) {
            throw ListServiceError.alreadyMember
        }

        try await doc.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }

    func removeMember(_ listId: String, userId: String) async throws {
        try await db.collection("lists").document(listId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }
}

enum ListServiceError: LocalizedError {
    case notAuthenticated
    case inviteNotFound
    case alreadyMember

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in."
        case .inviteNotFound: return "Invite link not found or expired."
        case .alreadyMember: return "You're already a member of this list."
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/ShoppingList/Services/ListService.swift
git commit -m "feat: add ListService with CRUD, real-time listeners, join/leave"
```

---

### Task 7: Item Service — CRUD, Check-Off, Flag Toggle

**Files:**
- Create: `ShoppingList/ShoppingList/Services/ItemService.swift`
- Create: `ShoppingList/ShoppingList/Services/HistoryService.swift`

- [ ] **Step 1: Write ItemService**

```swift
// ShoppingList/ShoppingList/Services/ItemService.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ItemService: ObservableObject {
    @Published var items: [Item] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let historyService = HistoryService()

    var activeItems: [Item] {
        items.filter { $0.status == .active }
    }

    var completedItems: [Item] {
        items.filter { $0.status == .completed && !$0.completedAt!.isOlderThan24Hours }
    }

    var itemsByCategory: [(ItemCategory, [Item])] {
        let grouped = Dictionary(grouping: activeItems) { $0.resolvedCategory }
        return grouped
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
            .map { ($0.key, $0.value.sorted { $0.addedAt > $1.addedAt }) }
    }

    func startListening(listId: String) {
        listener = db.collection("lists").document(listId)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.items = documents.compactMap { try? $0.data(as: Item.self) }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addItem(listId: String, rawInput: String, source: ItemSource = .text) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let item = Item(
            name: rawInput,
            rawInput: rawInput,
            addedBy: userId,
            addedAt: Date(),
            source: source
        )

        let docRef = try db.collection("lists").document(listId)
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

    func toggleComplete(listId: String, item: Item) async throws {
        guard let itemId = item.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        if item.isCompleted {
            try await db.collection("lists").document(listId)
                .collection("items").document(itemId)
                .updateData([
                    "status": ItemStatus.active.rawValue,
                    "completedAt": FieldValue.delete(),
                    "completedBy": FieldValue.delete()
                ])
        } else {
            try await db.collection("lists").document(listId)
                .collection("items").document(itemId)
                .updateData([
                    "status": ItemStatus.completed.rawValue,
                    "completedAt": FieldValue.serverTimestamp(),
                    "completedBy": userId
                ])

            try await historyService.recordAction(
                listId: listId,
                itemName: item.name,
                category: item.category,
                action: .completed,
                userId: userId
            )
        }
    }

    func toggleFlag(listId: String, item: Item) async throws {
        guard let itemId = item.id else { return }
        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .updateData(["flagged": !item.flagged])
    }

    func updateItem(listId: String, item: Item, name: String, quantity: String?, category: String?) async throws {
        guard let itemId = item.id else { return }
        var updates: [String: Any] = ["name": name]
        if let quantity { updates["quantity"] = quantity }
        if let category { updates["category"] = category }
        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .updateData(updates)
    }

    func deleteItem(listId: String, item: Item) async throws {
        guard let itemId = item.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        try await db.collection("lists").document(listId)
            .collection("items").document(itemId)
            .delete()

        try await historyService.recordAction(
            listId: listId,
            itemName: item.name,
            category: item.category,
            action: .removed,
            userId: userId
        )
    }
}
```

- [ ] **Step 2: Write HistoryService**

```swift
// ShoppingList/ShoppingList/Services/HistoryService.swift
import Foundation
import FirebaseFirestore

class HistoryService {
    private let db = Firestore.firestore()

    func recordAction(
        listId: String,
        itemName: String,
        category: String? = nil,
        action: HistoryAction,
        userId: String
    ) async throws {
        let entry = HistoryEntry(
            itemName: itemName,
            category: category,
            action: action,
            userId: userId,
            timestamp: Date(),
            purchaseCount: action == .completed ? 1 : 0
        )

        try db.collection("lists").document(listId)
            .collection("history")
            .addDocument(from: entry)

        // Increment purchaseCount on existing history entries for this item
        if action == .completed {
            let existing = try await db.collection("lists").document(listId)
                .collection("history")
                .whereField("itemName", isEqualTo: itemName)
                .whereField("action", isEqualTo: HistoryAction.completed.rawValue)
                .getDocuments()

            for doc in existing.documents {
                let currentCount = doc.data()["purchaseCount"] as? Int ?? 0
                try await doc.reference.updateData(["purchaseCount": currentCount + 1])
            }
        }
    }

    func getHistory(listId: String, limit: Int = 50) async throws -> [HistoryEntry] {
        let snapshot = try await db.collection("lists").document(listId)
            .collection("history")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: HistoryEntry.self) }
    }

    func getFrequentItems(listId: String) async throws -> [HistoryEntry] {
        let snapshot = try await db.collection("lists").document(listId)
            .collection("history")
            .whereField("action", isEqualTo: HistoryAction.completed.rawValue)
            .order(by: "purchaseCount", descending: true)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: HistoryEntry.self) }
    }
}
```

- [ ] **Step 3: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/ShoppingList/Services/ItemService.swift
git add ShoppingList/ShoppingList/Services/HistoryService.swift
git commit -m "feat: add ItemService and HistoryService with CRUD, check-off, flag, history"
```

---

## Phase 3: Core UI — Lists & Items

### Task 8: Tab Bar & Lists Home Screen

**Files:**
- Modify: `ShoppingList/ShoppingList/ContentView.swift`
- Create: `ShoppingList/ShoppingList/Views/Lists/ListsTabView.swift`
- Create: `ShoppingList/ShoppingList/Views/Lists/ListCardView.swift`
- Create: `ShoppingList/ShoppingList/Views/Lists/CreateListView.swift`
- Create: `ShoppingList/ShoppingList/Views/Components/MemberAvatarStack.swift`

- [ ] **Step 1: Write ContentView with tab bar**

```swift
// ShoppingList/ShoppingList/ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var listService = ListService()
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()

            TabView {
                ListsTabView()
                    .tabItem {
                        Label("Lists", systemImage: "list.bullet")
                    }

                ActivityTabView()
                    .tabItem {
                        Label("Activity", systemImage: "clock")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .tint(Theme.primaryGreen)
        }
        .environmentObject(listService)
        .environmentObject(networkMonitor)
        .onAppear { listService.startListening() }
        .onDisappear { listService.stopListening() }
    }
}
```

- [ ] **Step 2: Write MemberAvatarStack component**

```swift
// ShoppingList/ShoppingList/Views/Components/MemberAvatarStack.swift
import SwiftUI

struct MemberAvatarStack: View {
    let memberCount: Int
    let maxDisplay: Int = 3

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<min(memberCount, maxDisplay), id: \.self) { index in
                Circle()
                    .fill(Theme.secondaryGreen.opacity(0.3 + Double(index) * 0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.primaryGreen)
                    )
                    .overlay(Circle().stroke(Theme.surfaceWhite, lineWidth: 2))
            }

            if memberCount > maxDisplay {
                Text("+\(memberCount - maxDisplay)")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }
}
```

- [ ] **Step 3: Write ListCardView**

```swift
// ShoppingList/ShoppingList/Views/Lists/ListCardView.swift
import SwiftUI

struct ListCardView: View {
    let list: ShoppingList
    let itemCount: Int

    var body: some View {
        HStack(spacing: Theme.paddingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)

                Text("\(itemCount) items")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                MemberAvatarStack(memberCount: list.memberIds.count)

                Text(list.updatedAt.relativeDescription)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surfaceWhite)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: Theme.cardShadow, y: 2)
    }
}
```

- [ ] **Step 4: Write CreateListView**

```swift
// ShoppingList/ShoppingList/Views/Lists/CreateListView.swift
import SwiftUI

struct CreateListView: View {
    @EnvironmentObject var listService: ListService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("New List")
                }
            }
            .navigationTitle("Create List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            _ = try? await listService.createList(name: name)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
        }
    }
}
```

- [ ] **Step 5: Write ListsTabView**

```swift
// ShoppingList/ShoppingList/Views/Lists/ListsTabView.swift
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
                        .swipeActions(edge: .trailing) {
                            if list.ownerId == list.currentUserId {
                                Button(role: .destructive) {
                                    Task { try? await listService.deleteList(list.id ?? "") }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } else {
                                Button {
                                    Task { try? await listService.leaveList(list.id ?? "") }
                                } label: {
                                    Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                                .tint(.orange)
                            }
                        }
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
                ListDetailView(list: list)
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
```

- [ ] **Step 6: Create placeholder views for Activity and Profile tabs**

```swift
// ShoppingList/ShoppingList/Views/Activity/ActivityTabView.swift
import SwiftUI

struct ActivityTabView: View {
    var body: some View {
        NavigationStack {
            Text("Activity coming soon")
                .foregroundColor(Theme.textSecondary)
                .navigationTitle("Activity")
        }
    }
}
```

```swift
// ShoppingList/ShoppingList/Views/Settings/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Sign Out", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

- [ ] **Step 7: Make ShoppingList conform to Hashable for navigation**

Add to `ShoppingList.swift`:
```swift
extension ShoppingList: Hashable {
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

- [ ] **Step 8: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 9: Commit**

```bash
git add ShoppingList/ShoppingList/ContentView.swift
git add ShoppingList/ShoppingList/Views/
git add ShoppingList/ShoppingList/Models/ShoppingList.swift
git commit -m "feat: add tab bar, lists home screen, list cards, create list flow"
```

---

### Task 9: List Detail Screen — Items Grouped by Category

**Files:**
- Create: `ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift`
- Create: `ShoppingList/ShoppingList/Views/ListDetail/CategorySectionView.swift`
- Create: `ShoppingList/ShoppingList/Views/ListDetail/ItemRowView.swift`
- Create: `ShoppingList/ShoppingList/Views/ListDetail/CompletedSectionView.swift`
- Create: `ShoppingList/ShoppingList/Views/Components/FlagToggle.swift`

- [ ] **Step 1: Write FlagToggle component**

```swift
// ShoppingList/ShoppingList/Views/Components/FlagToggle.swift
import SwiftUI

struct FlagToggle: View {
    let isFlagged: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFlagged ? "star.fill" : "star")
                .foregroundColor(isFlagged ? Theme.flagAmber : Theme.textSecondary.opacity(0.4))
                .font(.system(size: 16))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Write ItemRowView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/ItemRowView.swift
import SwiftUI

struct ItemRowView: View {
    let item: Item
    let onToggleComplete: () -> Void
    let onToggleFlag: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FlagToggle(isFlagged: item.flagged, action: onToggleFlag)

            Button(action: onToggleComplete) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(item.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                            .strikethrough(item.isCompleted)

                        if let quantity = item.quantity, !quantity.isEmpty {
                            Text(quantity)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.secondaryGreen)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, Theme.paddingMedium)
    }
}
```

- [ ] **Step 3: Write CategorySectionView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/CategorySectionView.swift
import SwiftUI

struct CategorySectionView: View {
    let category: ItemCategory
    let items: [Item]
    let onToggleComplete: (Item) -> Void
    let onToggleFlag: (Item) -> Void
    let onDelete: (Item) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("\(category.emoji) \(category.rawValue)")
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
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 4: Write CompletedSectionView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/CompletedSectionView.swift
import SwiftUI

struct CompletedSectionView: View {
    let items: [Item]
    let onToggleComplete: (Item) -> Void

    @State private var isExpanded = false

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Theme.secondaryGreen)
                        Text("Completed (\(items.count))")
                            .font(Theme.captionFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.paddingMedium)
                    .padding(.vertical, Theme.paddingSmall)
                    .background(Theme.divider.opacity(0.5))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    ForEach(items) { item in
                        ItemRowView(
                            item: item,
                            onToggleComplete: { onToggleComplete(item) },
                            onToggleFlag: { }
                        )
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 5: Write ListDetailView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
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
                onMicTap: { /* Voice input — Task 12 */ },
                onCameraTap: { /* Photo input — Task 13 */ }
            )
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { itemService.startListening(listId: list.id ?? "") }
        .onDisappear { itemService.stopListening() }
    }
}
```

- [ ] **Step 6: Build and verify**

Build: Cmd+B. This will fail because `InputBarView` doesn't exist yet. Create it now.

- [ ] **Step 7: Write InputBarView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/InputBarView.swift
import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onMicTap: () -> Void
    let onCameraTap: () -> Void

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            TextField("Add items...", text: $text)
                .font(Theme.bodyFont)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            Button(action: onMicTap) {
                Image(systemName: "mic.fill")
                    .foregroundColor(Theme.primaryGreen)
                    .font(.system(size: 18))
            }

            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .foregroundColor(Theme.primaryGreen)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 10)
        .background(Theme.surfaceWhite)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.divider),
            alignment: .top
        )
    }
}
```

- [ ] **Step 8: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 9: Run app in simulator**

Run: Cmd+R with iPhone 16 simulator. Verify:
1. Sign-in screen appears with Apple Sign-In button
2. (After signing in) Tab bar shows with Lists, Activity, Profile tabs
3. Empty state shows on Lists tab
4. Can create a new list
5. Can tap into a list and see the input bar at bottom
6. Can type and add items
7. Items appear in the list grouped by "Other" category (AI categorization not wired yet)

- [ ] **Step 10: Commit**

```bash
git add ShoppingList/ShoppingList/Views/ListDetail/
git add ShoppingList/ShoppingList/Views/Components/FlagToggle.swift
git commit -m "feat: add list detail screen with category sections, item rows, input bar"
```

---

## Phase 4: Cloud Functions — AI Pipeline

### Task 10: Firebase Cloud Functions Project Setup

**Files:**
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/.eslintrc.js`
- Create: `functions/src/gemini.ts`
- Create: `functions/src/index.ts`

- [ ] **Step 1: Initialize Cloud Functions project**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
mkdir -p functions/src functions/test
```

- [ ] **Step 2: Write package.json**

```json
// functions/package.json
{
  "name": "shopping-list-functions",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "test": "jest --config jest.config.js"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google/generative-ai": "^0.21.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "@types/jest": "^29.5.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0",
    "firebase-functions-test": "^3.0.0"
  },
  "engines": {
    "node": "20"
  }
}
```

- [ ] **Step 3: Write tsconfig.json**

```json
// functions/tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020",
    "esModuleInterop": true,
    "resolveJsonModule": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

- [ ] **Step 4: Write jest.config.js**

```javascript
// functions/jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
};
```

- [ ] **Step 5: Write shared Gemini client**

```typescript
// functions/src/gemini.ts
import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";

const geminiApiKey = defineString("GEMINI_API_KEY");

let genAI: GoogleGenerativeAI | null = null;

function getGenAI(): GoogleGenerativeAI {
  if (!genAI) {
    genAI = new GoogleGenerativeAI(geminiApiKey.value());
  }
  return genAI;
}

export function getModel() {
  return getGenAI().getGenerativeModel({ model: "gemini-2.0-flash" });
}

export function getVisionModel() {
  return getGenAI().getGenerativeModel({ model: "gemini-2.0-flash" });
}

export const CATEGORIES = [
  "Produce", "Dairy", "Meat", "Bakery", "Frozen",
  "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
] as const;
```

- [ ] **Step 6: Write index.ts with placeholder exports**

```typescript
// functions/src/index.ts
export { onItemCreated } from "./parseInput";
export { parseImage } from "./parseImage";
export { suggestFrequentItems } from "./suggestFrequent";
export { reviewDuplicates } from "./reviewDuplicates";
```

- [ ] **Step 7: Install dependencies**

```bash
cd functions && npm install
```

- [ ] **Step 8: Commit**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
git add functions/package.json functions/tsconfig.json functions/jest.config.js
git add functions/src/gemini.ts functions/src/index.ts
git commit -m "feat: scaffold Cloud Functions project with Gemini client"
```

---

### Task 11: Cloud Functions — Parse Input & Categorize

**Files:**
- Create: `functions/src/parseInput.ts`
- Create: `functions/test/parseInput.test.ts`

- [ ] **Step 1: Write the parseInput test**

```typescript
// functions/test/parseInput.test.ts
import { parseRawInput } from "../src/parseInput";

// Mock the Gemini model
jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          items: [
            { name: "Chicken", quantity: "2 lbs", category: "Meat" },
            { name: "Rice", quantity: null, category: "Pantry" },
          ],
        }),
      },
    }),
  }),
  CATEGORIES: [
    "Produce", "Dairy", "Meat", "Bakery", "Frozen",
    "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
  ],
}));

describe("parseRawInput", () => {
  it("parses multi-item natural language input", async () => {
    const result = await parseRawInput("2 lbs chicken and some rice");
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({ name: "Chicken", quantity: "2 lbs", category: "Meat" });
    expect(result[1]).toEqual({ name: "Rice", quantity: null, category: "Pantry" });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd functions && npx jest test/parseInput.test.ts
```
Expected: FAIL — `parseRawInput` not found.

- [ ] **Step 3: Write parseInput Cloud Function**

```typescript
// functions/src/parseInput.ts
import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getModel, CATEGORIES } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface ParsedItem {
  name: string;
  quantity: string | null;
  category: string | null;
}

export async function parseRawInput(rawInput: string): Promise<ParsedItem[]> {
  const model = getModel();

  const prompt = `Parse this shopping list input into individual items.
For each item, extract:
- name: the item name (clean, capitalized)
- quantity: amount if mentioned (e.g., "2 lbs", "1 dozen"), or null
- category: one of [${CATEGORIES.join(", ")}]

Input: "${rawInput}"

Respond with ONLY valid JSON: {"items": [{"name": "...", "quantity": "..." or null, "category": "..."}]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();

  // Extract JSON from response (handle markdown code blocks)
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

export const onItemCreated = onDocumentCreated(
  "lists/{listId}/items/{itemId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const rawInput = data.rawInput;
    if (!rawInput) return;

    // Skip if already parsed (has a category)
    if (data.category) return;

    const listId = event.params.listId;
    const itemId = event.params.itemId;

    try {
      const parsedItems = await parseRawInput(rawInput);

      if (parsedItems.length === 1) {
        // Single item — update in place
        const item = parsedItems[0];
        await snapshot.ref.update({
          name: item.name,
          quantity: item.quantity || null,
          category: item.category || "Other",
        });
      } else {
        // Multiple items — create new docs, delete original
        const batch = db.batch();
        const itemsRef = db.collection("lists").document(listId).collection("items");

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
          });
        }

        batch.delete(snapshot.ref);
        await batch.commit();
      }
    } catch (error) {
      console.error("Parse failed, item will remain as-is:", error);
      // Graceful failure — item keeps rawInput as name
    }
  }
);
```

- [ ] **Step 4: Run tests**

```bash
cd functions && npx jest test/parseInput.test.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
git add functions/src/parseInput.ts functions/test/parseInput.test.ts
git commit -m "feat: add parseInput Cloud Function with Gemini NLP parsing"
```

---

### Task 11b: Cloud Functions — Parse Image

**Files:**
- Create: `functions/src/parseImage.ts`
- Create: `functions/test/parseImage.test.ts`

- [ ] **Step 1: Write parseImage test**

```typescript
// functions/test/parseImage.test.ts
import { extractItemsFromImage } from "../src/parseImage";

jest.mock("../src/gemini", () => ({
  getVisionModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          items: [
            { name: "Flour", quantity: "2 cups", category: "Pantry" },
            { name: "Eggs", quantity: "3", category: "Dairy" },
            { name: "Butter", quantity: "1 stick", category: "Dairy" },
          ],
        }),
      },
    }),
  }),
  CATEGORIES: [
    "Produce", "Dairy", "Meat", "Bakery", "Frozen",
    "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
  ],
}));

describe("extractItemsFromImage", () => {
  it("extracts items from a base64 image", async () => {
    const fakeBase64 = "iVBORw0KGgoAAAANS";
    const result = await extractItemsFromImage(fakeBase64, "image/jpeg");
    expect(result).toHaveLength(3);
    expect(result[0].name).toBe("Flour");
    expect(result[2].category).toBe("Dairy");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd functions && npx jest test/parseImage.test.ts
```
Expected: FAIL — `extractItemsFromImage` not found.

- [ ] **Step 3: Write parseImage Cloud Function**

```typescript
// functions/src/parseImage.ts
import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getVisionModel, CATEGORIES } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

interface ParsedItem {
  name: string;
  quantity: string | null;
  category: string | null;
}

export async function extractItemsFromImage(
  base64Image: string,
  mimeType: string
): Promise<ParsedItem[]> {
  const model = getVisionModel();

  const prompt = `Look at this image (recipe, shopping list, shelf, or handwritten note).
Extract every food/grocery item you can identify.
For each item, provide:
- name: clean item name
- quantity: amount if visible, or null
- category: one of [${CATEGORIES.join(", ")}]

Respond with ONLY valid JSON: {"items": [{"name": "...", "quantity": "..." or null, "category": "..."}]}`;

  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        data: base64Image,
        mimeType: mimeType,
      },
    },
  ]);

  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return [];

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.items || [];
  } catch {
    return [];
  }
}

export const parseImage = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { imageUrl } = request.data;
  if (!imageUrl) {
    throw new HttpsError("invalid-argument", "imageUrl is required");
  }

  // Download image from Firebase Storage
  const bucket = admin.storage().bucket();
  const file = bucket.file(imageUrl);
  const [buffer] = await file.download();
  const base64 = buffer.toString("base64");

  const [metadata] = await file.getMetadata();
  const mimeType = metadata.contentType || "image/jpeg";

  const items = await extractItemsFromImage(base64, mimeType);

  // Clean up the uploaded image
  await file.delete().catch(() => {});

  return { items };
});
```

- [ ] **Step 4: Run tests**

```bash
cd functions && npx jest test/parseImage.test.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
git add functions/src/parseImage.ts functions/test/parseImage.test.ts
git commit -m "feat: add parseImage Cloud Function with Gemini Vision"
```

---

### Task 11c: Cloud Functions — Suggest Frequent Items & Review Duplicates

**Files:**
- Create: `functions/src/suggestFrequent.ts`
- Create: `functions/src/reviewDuplicates.ts`
- Create: `functions/test/suggestFrequent.test.ts`
- Create: `functions/test/reviewDuplicates.test.ts`

- [ ] **Step 1: Write suggestFrequent test**

```typescript
// functions/test/suggestFrequent.test.ts
import { filterSuggestions } from "../src/suggestFrequent";

jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          suggestions: ["Milk", "Eggs", "Bread"],
        }),
      },
    }),
  }),
}));

describe("filterSuggestions", () => {
  it("filters frequent items using Gemini", async () => {
    const frequent = [
      { itemName: "Milk", purchaseCount: 10 },
      { itemName: "Eggs", purchaseCount: 8 },
      { itemName: "Bread", purchaseCount: 6 },
      { itemName: "Birthday Cake", purchaseCount: 1 },
    ];
    const currentItems = ["Eggs"];
    const result = await filterSuggestions(frequent, currentItems);
    expect(result).toContain("Milk");
    expect(result).toContain("Bread");
    expect(result).not.toContain("Eggs"); // Already on list
  });
});
```

- [ ] **Step 2: Write suggestFrequent function**

```typescript
// functions/src/suggestFrequent.ts
import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getModel } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface FrequentItem {
  itemName: string;
  purchaseCount: number;
}

export async function filterSuggestions(
  frequent: FrequentItem[],
  currentItemNames: string[]
): Promise<string[]> {
  const model = getModel();

  const currentSet = new Set(currentItemNames.map((n) => n.toLowerCase()));
  const candidates = frequent.filter(
    (f) => !currentSet.has(f.itemName.toLowerCase())
  );

  if (candidates.length === 0) return [];

  const prompt = `Given these frequently purchased grocery items with purchase counts:
${candidates.map((c) => `- ${c.itemName} (bought ${c.purchaseCount} times)`).join("\n")}

Filter out items that seem like one-time or seasonal purchases (e.g., birthday cake, holiday items).
Return only items that are likely regular staples.

Respond with ONLY valid JSON: {"suggestions": ["item1", "item2", ...]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return candidates.map((c) => c.itemName);

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.suggestions || [];
  } catch {
    return candidates.map((c) => c.itemName);
  }
}

export const suggestFrequentItems = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { listId } = request.data;
  if (!listId) {
    throw new HttpsError("invalid-argument", "listId is required");
  }

  // Get frequent items from history
  const historySnap = await db
    .collection("lists").doc(listId)
    .collection("history")
    .where("action", "==", "completed")
    .orderBy("purchaseCount", "desc")
    .limit(30)
    .get();

  const frequent: FrequentItem[] = historySnap.docs.map((doc) => ({
    itemName: doc.data().itemName,
    purchaseCount: doc.data().purchaseCount || 0,
  }));

  // Deduplicate by item name, keeping highest count
  const deduped = new Map<string, FrequentItem>();
  for (const item of frequent) {
    const key = item.itemName.toLowerCase();
    const existing = deduped.get(key);
    if (!existing || existing.purchaseCount < item.purchaseCount) {
      deduped.set(key, item);
    }
  }

  // Get current active items
  const itemsSnap = await db
    .collection("lists").doc(listId)
    .collection("items")
    .where("status", "==", "active")
    .get();

  const currentNames = itemsSnap.docs.map((doc) => doc.data().name);

  const suggestions = await filterSuggestions(
    Array.from(deduped.values()),
    currentNames
  );

  return { suggestions };
});
```

- [ ] **Step 3: Write reviewDuplicates test**

```typescript
// functions/test/reviewDuplicates.test.ts
import { findDuplicates } from "../src/reviewDuplicates";

jest.mock("../src/gemini", () => ({
  getModel: () => ({
    generateContent: jest.fn().mockResolvedValue({
      response: {
        text: () => JSON.stringify({
          groups: [
            { items: ["Milk", "Whole milk", "2% milk"], suggestion: "Milk" },
          ],
        }),
      },
    }),
  }),
}));

describe("findDuplicates", () => {
  it("groups similar items", async () => {
    const items = ["Milk", "Whole milk", "2% milk", "Bread", "Eggs"];
    const result = await findDuplicates(items);
    expect(result).toHaveLength(1);
    expect(result[0].items).toContain("Milk");
    expect(result[0].items).toContain("Whole milk");
    expect(result[0].suggestion).toBe("Milk");
  });
});
```

- [ ] **Step 4: Write reviewDuplicates function**

```typescript
// functions/src/reviewDuplicates.ts
import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getModel } from "./gemini";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface DuplicateGroup {
  items: string[];
  suggestion: string;
}

export async function findDuplicates(itemNames: string[]): Promise<DuplicateGroup[]> {
  if (itemNames.length < 2) return [];

  const model = getModel();

  const prompt = `Review this shopping list for duplicates or very similar items:
${itemNames.map((n) => `- ${n}`).join("\n")}

Group any items that are duplicates or near-duplicates (e.g., "milk" and "whole milk", "chicken breast" and "chicken").
For each group, suggest a single name to keep.
Only group items that are genuinely similar — don't group unrelated items.
If no duplicates found, return empty groups.

Respond with ONLY valid JSON: {"groups": [{"items": ["item1", "item2"], "suggestion": "best name"}]}`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return [];

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return parsed.groups || [];
  } catch {
    return [];
  }
}

export const reviewDuplicates = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { listId } = request.data;
  if (!listId) {
    throw new HttpsError("invalid-argument", "listId is required");
  }

  const itemsSnap = await db
    .collection("lists").doc(listId)
    .collection("items")
    .where("status", "==", "active")
    .get();

  const itemNames = itemsSnap.docs.map((doc) => doc.data().name as string);
  const groups = await findDuplicates(itemNames);

  return { groups };
});
```

- [ ] **Step 5: Run all Cloud Function tests**

```bash
cd functions && npx jest
```
Expected: All tests PASS.

- [ ] **Step 6: Build TypeScript**

```bash
cd functions && npm run build
```
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
git add functions/src/ functions/test/
git commit -m "feat: add suggestFrequent and reviewDuplicates Cloud Functions"
```

---

## Phase 5: Smart Input — Voice & Photo

### Task 12: Voice Input — Apple Speech

**Files:**
- Create: `ShoppingList/ShoppingList/Services/SpeechService.swift`
- Modify: `ShoppingList/ShoppingList/Views/ListDetail/InputBarView.swift`
- Modify: `ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift`

- [ ] **Step 1: Add microphone permission to Info.plist**

In Xcode, add to Info.plist:
- Key: `NSMicrophoneUsageDescription`
- Value: "Shopping List needs microphone access for voice input"
- Key: `NSSpeechRecognitionUsageDescription`
- Value: "Shopping List uses speech recognition to add items by voice"

- [ ] **Step 2: Write SpeechService**

```swift
// ShoppingList/ShoppingList/Services/SpeechService.swift
import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.isAuthorized = status == .authorized
            }
        }
    }

    func startRecording() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcribedText = ""

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
```

- [ ] **Step 3: Update InputBarView with voice recording state**

Replace `InputBarView` in `ShoppingList/ShoppingList/Views/ListDetail/InputBarView.swift`:

```swift
// ShoppingList/ShoppingList/Views/ListDetail/InputBarView.swift
import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onMicTap: () -> Void
    let onCameraTap: () -> Void
    var isRecording: Bool = false

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            TextField("Add items...", text: $text)
                .font(Theme.bodyFont)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            Button(action: onMicTap) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .foregroundColor(isRecording ? .red : Theme.primaryGreen)
                    .font(.system(size: 18))
                    .symbolEffect(.pulse, isActive: isRecording)
            }

            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .foregroundColor(Theme.primaryGreen)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 10)
        .background(Theme.surfaceWhite)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.divider),
            alignment: .top
        )
    }
}
```

- [ ] **Step 4: Wire voice input into ListDetailView**

Update `ListDetailView` to add speech support. Add these properties and update the body:

```swift
// Add to ListDetailView:
@StateObject private var speechService = SpeechService()

// Update the InputBarView call:
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
                inputText = ""
                Task {
                    try? await itemService.addItem(listId: list.id ?? "", rawInput: text, source: .voice)
                }
            }
        } else {
            try? speechService.startRecording()
        }
    },
    onCameraTap: { /* Photo input — Task 13 */ },
    isRecording: speechService.isRecording
)

// Add .onAppear modifier:
.onAppear {
    itemService.startListening(listId: list.id ?? "")
    speechService.requestAuthorization()
}
```

- [ ] **Step 5: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 6: Commit**

```bash
git add ShoppingList/ShoppingList/Services/SpeechService.swift
git add ShoppingList/ShoppingList/Views/ListDetail/InputBarView.swift
git add ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add voice input with Apple Speech on-device transcription"
```

---

### Task 13: Photo Input — Camera + Firebase Storage + AI Parsing

**Files:**
- Create: `ShoppingList/ShoppingList/Services/PhotoService.swift`
- Create: `ShoppingList/ShoppingList/Services/AIService.swift`
- Create: `ShoppingList/ShoppingList/Views/Photo/PhotoConfirmationView.swift`
- Modify: `ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift`

- [ ] **Step 1: Add camera permission to Info.plist**

In Xcode, add to Info.plist:
- Key: `NSCameraUsageDescription`
- Value: "Shopping List uses the camera to extract items from photos of recipes and lists"

- [ ] **Step 2: Write PhotoService**

```swift
// ShoppingList/ShoppingList/Services/PhotoService.swift
import Foundation
import FirebaseStorage
import UIKit

class PhotoService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw PhotoServiceError.compressionFailed
        }

        let filename = "photos/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(filename)

        _ = try await ref.putDataAsync(data, metadata: StorageMetadata(dictionary: [
            "contentType": "image/jpeg"
        ]))

        return filename
    }
}

enum PhotoServiceError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to process image."
        }
    }
}
```

- [ ] **Step 3: Write AIService (calls Cloud Functions)**

```swift
// ShoppingList/ShoppingList/Services/AIService.swift
import Foundation
import FirebaseFunctions

struct ParsedItem: Codable, Identifiable {
    let name: String
    let quantity: String?
    let category: String?

    var id: String { name + (quantity ?? "") }
}

struct DuplicateGroup: Codable, Identifiable {
    let items: [String]
    let suggestion: String

    var id: String { items.joined() }
}

class AIService {
    private let functions = Functions.functions()

    func parseImage(imageUrl: String) async throws -> [ParsedItem] {
        let result = try await functions.httpsCallable("parseImage").call(["imageUrl": imageUrl])

        guard let data = result.data as? [String: Any],
              let itemDicts = data["items"] as? [[String: Any]] else {
            return []
        }

        return itemDicts.compactMap { dict in
            guard let name = dict["name"] as? String else { return nil }
            return ParsedItem(
                name: name,
                quantity: dict["quantity"] as? String,
                category: dict["category"] as? String
            )
        }
    }

    func suggestFrequentItems(listId: String) async throws -> [String] {
        let result = try await functions.httpsCallable("suggestFrequentItems").call(["listId": listId])

        guard let data = result.data as? [String: Any],
              let suggestions = data["suggestions"] as? [String] else {
            return []
        }

        return suggestions
    }

    func reviewDuplicates(listId: String) async throws -> [DuplicateGroup] {
        let result = try await functions.httpsCallable("reviewDuplicates").call(["listId": listId])

        guard let data = result.data as? [String: Any],
              let groupDicts = data["groups"] as? [[String: Any]] else {
            return []
        }

        return groupDicts.compactMap { dict in
            guard let items = dict["items"] as? [String],
                  let suggestion = dict["suggestion"] as? String else { return nil }
            return DuplicateGroup(items: items, suggestion: suggestion)
        }
    }
}
```

- [ ] **Step 4: Write PhotoConfirmationView**

```swift
// ShoppingList/ShoppingList/Views/Photo/PhotoConfirmationView.swift
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
```

- [ ] **Step 5: Wire photo input into ListDetailView**

Add to `ListDetailView` properties:

```swift
@State private var showCamera = false
@State private var showPhotoConfirmation = false
@State private var capturedImage: UIImage?
@State private var parsedPhotoItems: [ParsedItem] = []
@State private var isParsingPhoto = false
private let photoService = PhotoService()
private let aiService = AIService()
```

Update the camera tap handler in `InputBarView`:

```swift
onCameraTap: {
    showCamera = true
}
```

Add these modifiers to the VStack in `ListDetailView`:

```swift
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
.onChange(of: capturedImage) { _, newImage in
    guard let image = newImage else { return }
    Task {
        isParsingPhoto = true
        do {
            let imageUrl = try await photoService.uploadImage(image)
            parsedPhotoItems = try await aiService.parseImage(imageUrl: imageUrl)
            showPhotoConfirmation = true
        } catch {
            // Show error — photo parsing failed
        }
        isParsingPhoto = false
        capturedImage = nil
    }
}
```

- [ ] **Step 6: Create ImagePicker UIViewControllerRepresentable**

Add to `PhotoService.swift` or create a new file:

```swift
// Add to ShoppingList/ShoppingList/Services/PhotoService.swift
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

- [ ] **Step 7: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 8: Commit**

```bash
git add ShoppingList/ShoppingList/Services/PhotoService.swift
git add ShoppingList/ShoppingList/Services/AIService.swift
git add ShoppingList/ShoppingList/Views/Photo/PhotoConfirmationView.swift
git add ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add photo input with camera capture, Firebase Storage, Gemini Vision parsing"
```

---

## Phase 6: Sharing & Invites

### Task 14: Invite Flow — Dynamic Links

**Files:**
- Create: `ShoppingList/ShoppingList/Services/InviteService.swift`
- Create: `ShoppingList/ShoppingList/Views/Settings/InviteView.swift`
- Create: `ShoppingList/ShoppingList/Views/Settings/ListSettingsView.swift`

- [ ] **Step 1: Write InviteService**

```swift
// ShoppingList/ShoppingList/Services/InviteService.swift
import Foundation
import FirebaseDynamicLinks

class InviteService {
    func generateInviteLink(inviteCode: String, listName: String) async throws -> URL {
        // Use your Firebase Dynamic Links domain
        let linkParameter = "https://YOUR_APP.page.link/invite?code=\(inviteCode)"
        guard let link = URL(string: linkParameter) else {
            throw InviteError.invalidLink
        }

        guard let linkBuilder = DynamicLinkComponents(
            link: link,
            domainURIPrefix: "https://YOUR_APP.page.link"
        ) else {
            throw InviteError.invalidLink
        }

        linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: Bundle.main.bundleIdentifier ?? "")
        linkBuilder.iOSParameters?.appStoreID = "YOUR_APP_STORE_ID"

        linkBuilder.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder.socialMetaTagParameters?.title = "Join \(listName)"
        linkBuilder.socialMetaTagParameters?.descriptionText = "You've been invited to a shared shopping list"

        guard let longURL = linkBuilder.url else {
            throw InviteError.invalidLink
        }

        return longURL
    }

    func handleIncomingLink(_ url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }
}

enum InviteError: LocalizedError {
    case invalidLink

    var errorDescription: String? {
        switch self {
        case .invalidLink: return "Could not create invite link."
        }
    }
}
```

- [ ] **Step 2: Write InviteView**

```swift
// ShoppingList/ShoppingList/Views/Settings/InviteView.swift
import SwiftUI

struct InviteView: View {
    let list: ShoppingList
    @State private var inviteURL: URL?
    @State private var isGenerating = false
    @State private var showShareSheet = false

    private let inviteService = InviteService()

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Theme.primaryGreen)

            Text("Invite to \(list.name)")
                .font(Theme.headlineFont)

            Text("Share this link with family members so they can join your list")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    isGenerating = true
                    inviteURL = try? await inviteService.generateInviteLink(
                        inviteCode: list.inviteCode,
                        listName: list.name
                    )
                    isGenerating = false
                    if inviteURL != nil {
                        showShareSheet = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(isGenerating ? "Generating..." : "Share Invite Link")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(Theme.cornerRadius)
            }
            .disabled(isGenerating)
        }
        .padding(Theme.paddingLarge)
        .sheet(isPresented: $showShareSheet) {
            if let url = inviteURL {
                ShareSheet(items: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

- [ ] **Step 3: Write ListSettingsView**

```swift
// ShoppingList/ShoppingList/Views/Settings/ListSettingsView.swift
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
```

- [ ] **Step 4: Add settings and invite access to ListDetailView**

Add a toolbar menu to `ListDetailView`:

```swift
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
```

Add the state variables:
```swift
@State private var showListSettings = false
@State private var showSuggestions = false
```

And the sheet modifiers:
```swift
.sheet(isPresented: $showListSettings) {
    ListSettingsView(list: list)
}
```

- [ ] **Step 5: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 6: Commit**

```bash
git add ShoppingList/ShoppingList/Services/InviteService.swift
git add ShoppingList/ShoppingList/Views/Settings/
git add ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add invite flow with Dynamic Links, list settings, member management"
```

---

## Phase 7: Activity, Suggestions & Duplicate Review

### Task 15: Activity Tab

**Files:**
- Modify: `ShoppingList/ShoppingList/Views/Activity/ActivityTabView.swift`
- Create: `ShoppingList/ShoppingList/Views/Activity/ActivityRowView.swift`

- [ ] **Step 1: Write ActivityRowView**

```swift
// ShoppingList/ShoppingList/Views/Activity/ActivityRowView.swift
import SwiftUI

struct ActivityRowView: View {
    let entry: HistoryEntry

    var actionIcon: String {
        switch entry.action {
        case .added: return "plus.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .removed: return "minus.circle.fill"
        case .reAdded: return "arrow.uturn.left.circle.fill"
        }
    }

    var actionColor: Color {
        switch entry.action {
        case .added: return Theme.primaryGreen
        case .completed: return Theme.secondaryGreen
        case .removed: return .red
        case .reAdded: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionIcon)
                .foregroundColor(actionColor)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.itemName)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    Text(entry.action.rawValue.capitalized)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text(entry.timestamp.relativeDescription)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            if let category = entry.category {
                Text(category)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.categoryTextColor(category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.categoryColor(category))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Update ActivityTabView**

```swift
// ShoppingList/ShoppingList/Views/Activity/ActivityTabView.swift
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
```

- [ ] **Step 3: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/ShoppingList/Views/Activity/
git commit -m "feat: add activity tab with unified history feed across all lists"
```

---

### Task 16: Suggestions & Duplicate Review Views

**Files:**
- Create: `ShoppingList/ShoppingList/Views/Suggestions/SuggestionsView.swift`
- Create: `ShoppingList/ShoppingList/Views/Duplicates/DuplicateReviewView.swift`
- Modify: `ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift`

- [ ] **Step 1: Write SuggestionsView**

```swift
// ShoppingList/ShoppingList/Views/Suggestions/SuggestionsView.swift
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
```

- [ ] **Step 2: Write DuplicateReviewView**

```swift
// ShoppingList/ShoppingList/Views/Duplicates/DuplicateReviewView.swift
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
```

- [ ] **Step 3: Wire suggestions and duplicates into ListDetailView**

Add to `ListDetailView` properties:

```swift
@State private var showDuplicates = false
@State private var duplicateGroups: [DuplicateGroup] = []
```

Add sheet modifiers:

```swift
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
                // Keep the suggested name, delete others
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
```

Add the duplicate check method:

```swift
private func runDuplicateCheck() async {
    do {
        duplicateGroups = try await aiService.reviewDuplicates(listId: list.id ?? "")
        showDuplicates = true
    } catch {
        // Handle error
    }
}
```

- [ ] **Step 4: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/ShoppingList/Views/Suggestions/
git add ShoppingList/ShoppingList/Views/Duplicates/
git add ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add AI suggestions and duplicate review views"
```

---

## Phase 8: Notifications & Widgets

### Task 17: Push Notifications

**Files:**
- Create: `ShoppingList/ShoppingList/Services/NotificationService.swift`
- Create: `functions/src/notifications.ts`
- Modify: `ShoppingList/ShoppingList/ShoppingListApp.swift`

- [ ] **Step 1: Enable Push Notifications capability**

In Xcode:
1. Target → Signing & Capabilities → + Capability → Push Notifications
2. + Capability → Background Modes → check "Remote notifications"

- [ ] **Step 2: Write NotificationService**

```swift
// ShoppingList/ShoppingList/Services/NotificationService.swift
import Foundation
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken,
              let userId = Auth.auth().currentUser?.uid else { return }

        // Store FCM token in user document
        Firestore.firestore().collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}
```

- [ ] **Step 3: Write notifications Cloud Function**

```typescript
// functions/src/notifications.ts
import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const onItemAdded = onDocumentCreated(
  "lists/{listId}/items/{itemId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const listId = event.params.listId;
    const addedBy = data.addedBy;

    // Get the list to find other members
    const listDoc = await db.collection("lists").doc(listId).get();
    if (!listDoc.exists) return;

    const listData = listDoc.data()!;
    const memberIds = (listData.memberIds as string[]).filter((id) => id !== addedBy);

    if (memberIds.length === 0) return;

    // Get the adder's display name
    const userDoc = await db.collection("users").doc(addedBy).get();
    const userName = userDoc.data()?.displayName || "Someone";

    // Get FCM tokens for other members
    const tokens: string[] = [];
    for (const memberId of memberIds) {
      const memberDoc = await db.collection("users").doc(memberId).get();
      const token = memberDoc.data()?.fcmToken;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: listData.name,
        body: `${userName} added "${data.name || data.rawInput}"`,
      },
      data: {
        listId: listId,
        type: "item_added",
      },
    });
  }
);
```

- [ ] **Step 4: Export notification function**

Add to `functions/src/index.ts`:
```typescript
export { onItemAdded } from "./notifications";
```

- [ ] **Step 5: Wire NotificationService into app entry**

Update `ShoppingListApp.swift`:

```swift
@StateObject private var notificationService = NotificationService()

// In the body, after auth check:
.onAppear {
    notificationService.requestPermission()
}
```

- [ ] **Step 6: Build iOS + Cloud Functions**

```bash
# iOS
# Cmd+B in Xcode — Expected: Build Succeeded

# Cloud Functions
cd functions && npm run build
```

- [ ] **Step 7: Commit**

```bash
cd /Users/tgjerm01/Programming/shopping-list-app
git add ShoppingList/ShoppingList/Services/NotificationService.swift
git add ShoppingList/ShoppingList/ShoppingListApp.swift
git add functions/src/notifications.ts functions/src/index.ts
git commit -m "feat: add push notifications with FCM for item additions"
```

---

### Task 18: iOS Widgets

**Files:**
- Create: `ShoppingListWidget/ShoppingListWidget.swift`
- Create: `ShoppingListWidget/WidgetViews.swift`

- [ ] **Step 1: Add Widget Extension target**

In Xcode:
1. File → New → Target → Widget Extension
2. Product Name: `ShoppingListWidget`
3. Include Configuration App Intent: No
4. Activate the scheme when prompted

- [ ] **Step 2: Write Widget Timeline Provider & Entry**

```swift
// ShoppingListWidget/ShoppingListWidget.swift
import WidgetKit
import SwiftUI

struct ShoppingListEntry: TimelineEntry {
    let date: Date
    let listName: String
    let items: [WidgetItem]
    let totalCount: Int
}

struct WidgetItem: Identifiable {
    let id = UUID()
    let name: String
    let isFlagged: Bool
    let category: String
}

struct ShoppingListProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoppingListEntry {
        ShoppingListEntry(
            date: Date(),
            listName: "Groceries",
            items: [
                WidgetItem(name: "Milk", isFlagged: true, category: "Dairy"),
                WidgetItem(name: "Bread", isFlagged: false, category: "Bakery"),
                WidgetItem(name: "Eggs", isFlagged: false, category: "Dairy"),
            ],
            totalCount: 8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShoppingListEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingListEntry>) -> Void) {
        // For now, use placeholder data
        // Full implementation would read from shared App Group container
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

@main
struct ShoppingListWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShoppingListWidget()
    }
}

struct ShoppingListWidget: Widget {
    let kind = "ShoppingListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoppingListProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Shopping List")
        .description("See your shopping list items at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

- [ ] **Step 3: Write Widget Views**

```swift
// ShoppingListWidget/WidgetViews.swift
import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: ShoppingListEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: ShoppingListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.196))
                    .font(.system(size: 14))
                Text(entry.listName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
            }

            Text("\(entry.totalCount) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            ForEach(entry.items.prefix(3)) { item in
                HStack(spacing: 4) {
                    if item.isFlagged {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0))
                    }
                    Text(item.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.99, blue: 0.976), for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: ShoppingListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.196))
                Text(entry.listName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(entry.totalCount) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            ForEach(entry.items.prefix(4)) { item in
                HStack(spacing: 6) {
                    if item.isFlagged {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0))
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    Text(item.name)
                        .font(.system(size: 13))
                        .lineLimit(1)

                    Spacer()

                    Text(item.category)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.99, blue: 0.976), for: .widget)
    }
}
```

- [ ] **Step 4: Build and verify**

Build: Cmd+B with the ShoppingListWidget scheme. Expected: Build Succeeded.

- [ ] **Step 5: Commit**

```bash
git add ShoppingListWidget/
git commit -m "feat: add iOS home screen widgets (small + medium) for shopping list"
```

---

## Phase 9: Profile & Edit Item

### Task 19: Profile View & Edit Item Sheet

**Files:**
- Modify: `ShoppingList/ShoppingList/Views/Settings/ProfileView.swift`
- Create: `ShoppingList/ShoppingList/Views/ListDetail/EditItemView.swift`

- [ ] **Step 1: Write full ProfileView**

```swift
// ShoppingList/ShoppingList/Views/Settings/ProfileView.swift
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
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

                Section("Preferences") {
                    NavigationLink {
                        Text("Notification settings")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

- [ ] **Step 2: Write EditItemView**

```swift
// ShoppingList/ShoppingList/Views/ListDetail/EditItemView.swift
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
```

- [ ] **Step 3: Wire EditItemView into ListDetailView**

Add state:
```swift
@State private var editingItem: Item?
```

Add long-press gesture to `ItemRowView` (or add edit action to swipe actions in `CategorySectionView`):

```swift
// In CategorySectionView, add to the swipe actions:
.swipeActions(edge: .leading) {
    Button {
        editingItem = item
    } label: {
        Label("Edit", systemImage: "pencil")
    }
    .tint(Theme.primaryGreen)
}
```

Add sheet:
```swift
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
```

- [ ] **Step 4: Build and verify**

Build: Cmd+B. Expected: Build Succeeded.

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/ShoppingList/Views/Settings/ProfileView.swift
git add ShoppingList/ShoppingList/Views/ListDetail/EditItemView.swift
git add ShoppingList/ShoppingList/Views/ListDetail/ListDetailView.swift
git commit -m "feat: add profile view and edit item sheet with category picker"
```

---

## Phase 10: Final Integration & Deploy

### Task 20: Firebase Deployment & End-to-End Testing

**Files:**
- Modify: `functions/src/index.ts` (verify all exports)
- Verify: `firestore.rules`
- Verify: `firebase.json`

- [ ] **Step 1: Set Gemini API key as Firebase config**

```bash
firebase functions:secrets:set GEMINI_API_KEY
# Enter your Gemini API key when prompted
```

- [ ] **Step 2: Deploy Firestore rules and indexes**

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Expected: Deploy complete.

- [ ] **Step 3: Deploy Cloud Functions**

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Expected: All 5 functions deployed successfully (onItemCreated, parseImage, suggestFrequentItems, reviewDuplicates, onItemAdded).

- [ ] **Step 4: Run full Cloud Functions test suite**

```bash
cd functions && npx jest --verbose
```
Expected: All tests PASS.

- [ ] **Step 5: End-to-end test in simulator**

Run the app (Cmd+R) and verify each flow:

1. **Sign in** with Apple (use simulator's test credentials)
2. **Create a list** — "Weekly Groceries" — appears on home screen
3. **Add item via text** — type "2 lbs chicken and some rice" — verify two items appear after AI parsing
4. **Flag an item** — tap star, verify it turns amber
5. **Check off an item** — tap it, verify it moves to Completed section
6. **Check the Activity tab** — verify history entries appear
7. **Voice input** — tap mic, speak, verify transcription (requires physical device)
8. **Photo input** — tap camera, take a photo (requires physical device)
9. **Suggestions** — open suggestions from menu (requires history to exist)
10. **Duplicate check** — add "Milk" and "Whole milk", run duplicate review
11. **List settings** — rename list, verify change
12. **Offline** — enable airplane mode, add an item, disable airplane mode, verify sync

- [ ] **Step 6: Create storage rules**

```
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /photos/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

```bash
firebase deploy --only storage:rules
```

- [ ] **Step 7: Final commit**

```bash
git add storage.rules
git add -A
git commit -m "feat: complete Firebase deployment config and storage rules"
```

---

## Summary

| Phase | Tasks | What it builds |
|-------|-------|----------------|
| 1. Foundation | 1-3 | Xcode project, Firebase, theme, data models |
| 2. Auth & Services | 4-7 | Apple Sign-In, network monitor, list/item/history services |
| 3. Core UI | 8-9 | Tab bar, lists home, list detail with categories |
| 4. Cloud Functions | 10-11c | Gemini-powered parsing, categorization, suggestions, duplicates |
| 5. Smart Input | 12-13 | Voice (Apple Speech) and photo (Gemini Vision) input |
| 6. Sharing | 14 | Dynamic Links invites, list settings, member management |
| 7. Activity & AI | 15-16 | Activity feed, suggestions view, duplicate review |
| 8. Notifications & Widgets | 17-18 | FCM push notifications, home screen widgets |
| 9. Profile & Edit | 19 | Profile screen, edit item with category picker |
| 10. Deploy & Test | 20 | Firebase deployment, end-to-end testing |
