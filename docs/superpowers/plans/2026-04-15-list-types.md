# List Types & Primary List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a list type system (Groceries, Pharmacy, Event, DIY Project, Custom) with per-type item categories, a primary list hero card on the home screen, archiving, and event date dimming.

**Architecture:** New `ListType` enum drives per-type behavior (icon, color, categories). `ShoppingList` model gets `type`, `eventDate`, and `isArchived` fields with backward-compatible defaults. `ItemCategory` expands with new cases per type. Home screen splits into primary hero card / other lists / archived sections. Cloud Function reads list type to parameterize Gemini's category prompt.

**Tech Stack:** Swift/SwiftUI (iOS 17+), Firebase Firestore, XcodeGen, TypeScript Cloud Functions, Gemini 2.0 Flash

---

## File Map

### New Files

| File | Responsibility |
|------|---------------|
| `ShoppingList/Models/ListType.swift` | `ListType` enum with display name, icon, theme color, item categories |
| `ShoppingList/Views/Lists/PrimaryListCardView.swift` | Hero card for the primary list on home screen |
| `ShoppingListTests/Models/ListTypeTests.swift` | Unit tests for `ListType` enum |
| `functions/src/categories.ts` | Per-list-type category mappings (extracted from `gemini.ts`) |
| `functions/test/categories.test.ts` | Tests for category mapping |

### Modified Files

| File | Changes |
|------|---------|
| `ShoppingList/Models/ItemCategory.swift` | Add ~18 new cases for pharmacy/event/DIY/custom; add `categories(for:)` static method |
| `ShoppingList/Models/ShoppingList.swift` | Add `type: ListType`, `eventDate: Date?`, `isArchived: Bool` fields with defaults |
| `ShoppingList/Theme/SoftSageTheme.swift` | Add `categoryColor`/`categoryTextColor` entries for new categories; add `listTypeColor()` |
| `ShoppingList/Services/ListService.swift` | Update `createList()` to accept type/eventDate; add `setDefaultList()`, `archiveList()` |
| `ShoppingList/Services/AuthService.swift` | Create default Groceries list + set `defaultListId` on sign-up |
| `ShoppingList/Views/Lists/ListsTabView.swift` | Split into primary/other/archived sections; subscribe to primary list items |
| `ShoppingList/Views/Lists/ListCardView.swift` | Add type icon, handle dimmed state for past events |
| `ShoppingList/Views/Lists/CreateListView.swift` | Redesign: type chips, event date picker, set-as-primary toggle |
| `ShoppingList/Views/Settings/ListSettingsView.swift` | Add "Set as Primary" and "Archive/Unarchive" options |
| `ShoppingListTests/Models/ItemCategoryTests.swift` | Update tests for expanded enum |
| `ShoppingListTests/Models/ShoppingListTests.swift` | Add decoding tests for new fields |
| `ShoppingListUITests/ShoppingListUITests.swift` | Add list type, primary, archive, and category UI tests |
| `functions/src/gemini.ts` | Remove hardcoded `CATEGORIES` (moved to `categories.ts`) |
| `functions/src/parseInput.ts` | Read list type from parent doc; pass type-specific categories to Gemini |

---

## Task 1: ListType Enum

**Files:**
- Create: `ShoppingList/Models/ListType.swift`
- Create: `ShoppingListTests/Models/ListTypeTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `ShoppingListTests/Models/ListTypeTests.swift`:

```swift
import XCTest
@testable import ShoppingList

final class ListTypeTests: XCTestCase {
    func testAllCasesHaveDisplayName() {
        for type in ListType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type) missing displayName")
        }
    }

    func testAllCasesHaveIcon() {
        for type in ListType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) missing icon")
        }
    }

    func testAllCasesHaveItemCategories() {
        for type in ListType.allCases {
            XCTAssertFalse(type.itemCategories.isEmpty, "\(type) has no item categories")
        }
    }

    func testAllCategorySetsEndWithOther() {
        for type in ListType.allCases {
            XCTAssertEqual(type.itemCategories.last, .other, "\(type) should end with .other")
        }
    }

    func testGroceriesCategoriesMatchExistingSet() {
        let expected: [ItemCategory] = [
            .produce, .dairy, .meat, .bakery, .frozen,
            .beverages, .snacks, .pantry, .household, .personalCare, .other
        ]
        XCTAssertEqual(ListType.groceries.itemCategories, expected)
    }

    func testCodableRoundTrip() throws {
        for type in ListType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(ListType.self, from: data)
            XCTAssertEqual(type, decoded)
        }
    }

    func testRawValues() {
        XCTAssertEqual(ListType.groceries.rawValue, "groceries")
        XCTAssertEqual(ListType.pharmacy.rawValue, "pharmacy")
        XCTAssertEqual(ListType.event.rawValue, "event")
        XCTAssertEqual(ListType.diyProject.rawValue, "diyProject")
        XCTAssertEqual(ListType.custom.rawValue, "custom")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests/ListTypeTests -quiet 2>&1 | tail -20`

Expected: Compilation error — `ListType` not defined.

- [ ] **Step 3: Create the ListType enum**

Create `ShoppingList/Models/ListType.swift`:

```swift
import SwiftUI

enum ListType: String, Codable, CaseIterable, Identifiable {
    case groceries
    case pharmacy
    case event
    case diyProject
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groceries:  return String(localized: "Groceries")
        case .pharmacy:   return String(localized: "Pharmacy")
        case .event:      return String(localized: "Party / Event")
        case .diyProject: return String(localized: "DIY Project")
        case .custom:     return String(localized: "Custom")
        }
    }

    var icon: String {
        switch self {
        case .groceries:  return "cart.fill"
        case .pharmacy:   return "cross.case.fill"
        case .event:      return "party.popper.fill"
        case .diyProject: return "hammer.fill"
        case .custom:     return "list.bullet"
        }
    }

    var themeColor: Color {
        switch self {
        case .groceries:  return Color(red: 0.18, green: 0.49, blue: 0.196)  // #2E7D32
        case .pharmacy:   return Color(red: 0.082, green: 0.396, blue: 0.753) // #1565C0
        case .event:      return Color(red: 0.929, green: 0.424, blue: 0.0)   // #EF6C00
        case .diyProject: return Color(red: 0.263, green: 0.388, blue: 0.424) // #43636C
        case .custom:     return Color(red: 0.459, green: 0.459, blue: 0.459) // #757575
        }
    }

    var itemCategories: [ItemCategory] {
        switch self {
        case .groceries:
            return [.produce, .dairy, .meat, .bakery, .frozen, .beverages, .snacks, .pantry, .household, .personalCare, .other]
        case .pharmacy:
            return [.prescriptions, .overTheCounter, .vitaminsSupplements, .firstAid, .personalCarePharmacy, .baby, .other]
        case .event:
            return [.drinks, .food, .decorations, .tableware, .activities, .other]
        case .diyProject:
            return [.tools, .electrical, .plumbing, .paint, .garden, .lumber, .fasteners, .other]
        case .custom:
            return [.general, .other]
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they fail (ItemCategory cases don't exist yet)**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests/ListTypeTests -quiet 2>&1 | tail -20`

Expected: Compilation error — new `ItemCategory` cases not defined yet. This is expected; we'll fix in Task 2. Move on.

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Models/ListType.swift ShoppingListTests/Models/ListTypeTests.swift
git commit -m "feat: add ListType enum and tests (pending ItemCategory expansion)"
```

---

## Task 2: Expand ItemCategory Enum

**Files:**
- Modify: `ShoppingList/Models/ItemCategory.swift`
- Modify: `ShoppingListTests/Models/ItemCategoryTests.swift`

- [ ] **Step 1: Add new cases to ItemCategory**

In `ShoppingList/Models/ItemCategory.swift`, add new cases after `other`:

```swift
enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    // Grocery (existing)
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

    // Pharmacy
    case prescriptions = "Prescriptions"
    case overTheCounter = "Over-the-Counter"
    case vitaminsSupplements = "Vitamins & Supplements"
    case firstAid = "First Aid"
    case personalCarePharmacy = "Personal Care (Pharmacy)"
    case baby = "Baby"

    // Event
    case drinks = "Drinks"
    case food = "Food"
    case decorations = "Decorations"
    case tableware = "Tableware"
    case activities = "Activities"

    // DIY Project
    case tools = "Tools"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case paint = "Paint"
    case garden = "Garden"
    case lumber = "Lumber"
    case fasteners = "Fasteners"

    // Custom
    case general = "General"

    var id: String { rawValue }

    func localizedName(for language: String) -> String {
        let locale = Locale(identifier: language)
        return String(localized: String.LocalizationValue(rawValue), locale: locale)
    }

    var emoji: String {
        switch self {
        // Grocery
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
        // Pharmacy
        case .prescriptions:        return "💊"
        case .overTheCounter:       return "🩹"
        case .vitaminsSupplements:  return "💉"
        case .firstAid:             return "🩺"
        case .personalCarePharmacy: return "🧴"
        case .baby:                 return "🍼"
        // Event
        case .drinks:       return "🥂"
        case .food:         return "🍕"
        case .decorations:  return "🎈"
        case .tableware:    return "🍽️"
        case .activities:   return "🎯"
        // DIY Project
        case .tools:        return "🔧"
        case .electrical:   return "⚡"
        case .plumbing:     return "🔩"
        case .paint:        return "🎨"
        case .garden:       return "🌱"
        case .lumber:       return "🪵"
        case .fasteners:    return "🔩"
        // Custom
        case .general:      return "📋"
        }
    }

    var sortOrder: Int {
        switch self {
        // Grocery
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
        // Pharmacy
        case .prescriptions: return 0
        case .overTheCounter: return 1
        case .vitaminsSupplements: return 2
        case .firstAid: return 3
        case .personalCarePharmacy: return 4
        case .baby: return 5
        // Event
        case .drinks: return 0
        case .food: return 1
        case .decorations: return 2
        case .tableware: return 3
        case .activities: return 4
        // DIY Project
        case .tools: return 0
        case .electrical: return 1
        case .plumbing: return 2
        case .paint: return 3
        case .garden: return 4
        case .lumber: return 5
        case .fasteners: return 6
        // Custom
        case .general: return 0
        }
    }

    /// Returns the valid categories for a given list type
    static func categories(for listType: ListType) -> [ItemCategory] {
        listType.itemCategories
    }
}
```

Note: `sortOrder` values are per-type (0-indexed within each type's category set). This works because items are only shown within one list at a time, so sort orders don't need to be globally unique — they just need to order correctly within a list type's category set.

- [ ] **Step 2: Update the existing unit tests**

In `ShoppingListTests/Models/ItemCategoryTests.swift`, replace the `testAllCasesHaveUniqueSortOrder` test — sort orders are now per-type, not globally unique:

```swift
import XCTest
@testable import ShoppingList

final class ItemCategoryTests: XCTestCase {
    func testAllCasesHaveEmoji() {
        for category in ItemCategory.allCases {
            XCTAssertFalse(category.emoji.isEmpty, "\(category.rawValue) missing emoji")
        }
    }

    func testSortOrdersUniqueWithinEachListType() {
        for type in ListType.allCases {
            let categories = type.itemCategories
            let orders = categories.map(\.sortOrder)
            XCTAssertEqual(orders.count, Set(orders).count, "\(type) has duplicate sort orders")
        }
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

    func testNewCategoriesExist() {
        // Pharmacy
        XCTAssertEqual(ItemCategory.prescriptions.rawValue, "Prescriptions")
        XCTAssertEqual(ItemCategory.overTheCounter.rawValue, "Over-the-Counter")
        // Event
        XCTAssertEqual(ItemCategory.drinks.rawValue, "Drinks")
        XCTAssertEqual(ItemCategory.decorations.rawValue, "Decorations")
        // DIY
        XCTAssertEqual(ItemCategory.tools.rawValue, "Tools")
        XCTAssertEqual(ItemCategory.lumber.rawValue, "Lumber")
        // Custom
        XCTAssertEqual(ItemCategory.general.rawValue, "General")
    }

    func testCategoriesForListType() {
        let pharmacyCategories = ItemCategory.categories(for: .pharmacy)
        XCTAssertTrue(pharmacyCategories.contains(.prescriptions))
        XCTAssertTrue(pharmacyCategories.contains(.overTheCounter))
        XCTAssertFalse(pharmacyCategories.contains(.produce))
        XCTAssertTrue(pharmacyCategories.contains(.other))
    }
}
```

- [ ] **Step 3: Run all unit tests**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests -quiet 2>&1 | tail -20`

Expected: All tests PASS (ListTypeTests + ItemCategoryTests + ShoppingListModelTests).

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/Models/ItemCategory.swift ShoppingList/Models/ListType.swift ShoppingListTests/Models/ItemCategoryTests.swift ShoppingListTests/Models/ListTypeTests.swift
git commit -m "feat: expand ItemCategory with pharmacy/event/DIY/custom cases and add ListType enum"
```

---

## Task 3: ShoppingList Model Changes

**Files:**
- Modify: `ShoppingList/Models/ShoppingList.swift`
- Modify: `ShoppingListTests/Models/ShoppingListTests.swift`

- [ ] **Step 1: Write failing tests for new fields**

Add to `ShoppingListTests/Models/ShoppingListTests.swift`:

```swift
func testDefaultTypeIsGroceries() {
    let list = ShoppingList(
        name: "Test",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123"
    )
    XCTAssertEqual(list.type, .groceries)
}

func testDefaultIsArchivedIsFalse() {
    let list = ShoppingList(
        name: "Test",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123"
    )
    XCTAssertFalse(list.isArchived)
}

func testEventDateDefaultsToNil() {
    let list = ShoppingList(
        name: "Test",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123"
    )
    XCTAssertNil(list.eventDate)
}

func testDecodingWithoutTypeDefaultsToGroceries() throws {
    let json = """
    {
        "name": "Old List",
        "ownerId": "owner1",
        "memberIds": ["owner1"],
        "createdAt": 1000000,
        "updatedAt": 1000000,
        "inviteCode": "abc123"
    }
    """.data(using: .utf8)!

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    let list = try decoder.decode(ShoppingList.self, from: json)
    XCTAssertEqual(list.type, .groceries)
    XCTAssertFalse(list.isArchived)
    XCTAssertNil(list.eventDate)
}

func testIsPastEventReturnsTrueForPastDate() {
    var list = ShoppingList(
        name: "Past Party",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123",
        type: .event,
        eventDate: Date.distantPast
    )
    XCTAssertTrue(list.isPastEvent)
}

func testIsPastEventReturnsFalseForFutureDate() {
    var list = ShoppingList(
        name: "Future Party",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123",
        type: .event,
        eventDate: Date.distantFuture
    )
    XCTAssertFalse(list.isPastEvent)
}

func testIsPastEventReturnsFalseForNonEventType() {
    var list = ShoppingList(
        name: "Groceries",
        ownerId: "owner1",
        memberIds: ["owner1"],
        createdAt: Date(),
        updatedAt: Date(),
        inviteCode: "abc123"
    )
    XCTAssertFalse(list.isPastEvent)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests/ShoppingListModelTests -quiet 2>&1 | tail -20`

Expected: Compilation errors — `type`, `isArchived`, `eventDate`, `isPastEvent` don't exist on `ShoppingList`.

- [ ] **Step 3: Update the ShoppingList model**

Replace `ShoppingList/Models/ShoppingList.swift`:

```swift
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
    var language: String?
    var type: ListType
    var eventDate: Date?
    var isArchived: Bool

    var currentUserId: String? = nil

    var isMember: Bool {
        guard let userId = currentUserId else { return false }
        return memberIds.contains(userId)
    }

    var isPastEvent: Bool {
        guard type == .event, let eventDate else { return false }
        return eventDate < Date()
    }

    init(
        name: String,
        ownerId: String,
        memberIds: [String],
        createdAt: Date,
        updatedAt: Date,
        inviteCode: String,
        language: String? = nil,
        type: ListType = .groceries,
        eventDate: Date? = nil,
        isArchived: Bool = false
    ) {
        self.name = name
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.inviteCode = inviteCode
        self.language = language
        self.type = type
        self.eventDate = eventDate
        self.isArchived = isArchived
    }

    enum CodingKeys: String, CodingKey {
        case id, name, ownerId, memberIds, createdAt, updatedAt, inviteCode, language, type, eventDate, isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        memberIds = try container.decode([String].self, forKey: .memberIds)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        type = try container.decodeIfPresent(ListType.self, forKey: .type) ?? .groceries
        eventDate = try container.decodeIfPresent(Date.self, forKey: .eventDate)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}

extension ShoppingList: Hashable {
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

- [ ] **Step 4: Run all unit tests**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests -quiet 2>&1 | tail -20`

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add ShoppingList/Models/ShoppingList.swift ShoppingListTests/Models/ShoppingListTests.swift
git commit -m "feat: add type, eventDate, isArchived to ShoppingList with backward-compatible decoding"
```

---

## Task 4: Theme Expansion

**Files:**
- Modify: `ShoppingList/Theme/SoftSageTheme.swift`

- [ ] **Step 1: Add category colors for new categories**

In `SoftSageTheme.swift`, add new cases to both `categoryColor` and `categoryTextColor`. Add them to the switch statements before the `default` case:

In `categoryColor(_:)`, add before `default`:

```swift
// Pharmacy
case "Prescriptions":              return Color(red: 0.89, green: 0.949, blue: 0.992)  // Light blue
case "Over-the-Counter":           return Color(red: 0.945, green: 0.929, blue: 0.973) // Light purple
case "Vitamins & Supplements":     return Color(red: 0.945, green: 0.973, blue: 0.914) // Light green
case "First Aid":                  return Color(red: 0.988, green: 0.894, blue: 0.882) // Light red
case "Personal Care (Pharmacy)":   return Color(red: 0.969, green: 0.914, blue: 0.957) // Light pink
case "Baby":                       return Color(red: 0.882, green: 0.961, blue: 0.996) // Light cyan
// Event
case "Drinks":                     return Color(red: 0.914, green: 0.906, blue: 0.965) // Light indigo
case "Food":                       return Color(red: 1.0, green: 0.953, blue: 0.878)   // Light orange
case "Decorations":                return Color(red: 1.0, green: 0.965, blue: 0.886)   // Light amber
case "Tableware":                  return Color(red: 0.914, green: 0.941, blue: 0.945) // Light slate
case "Activities":                 return Color(red: 0.937, green: 0.922, blue: 0.882) // Light tan
// DIY Project
case "Tools":                      return Color(red: 0.914, green: 0.941, blue: 0.945) // Light slate
case "Electrical":                 return Color(red: 1.0, green: 0.965, blue: 0.886)   // Light amber
case "Plumbing":                   return Color(red: 0.89, green: 0.949, blue: 0.992)  // Light blue
case "Paint":                      return Color(red: 0.945, green: 0.929, blue: 0.973) // Light purple
case "Garden":                     return Color(red: 0.945, green: 0.973, blue: 0.914) // Light green
case "Lumber":                     return Color(red: 0.937, green: 0.922, blue: 0.882) // Light tan
case "Fasteners":                  return Color(red: 0.914, green: 0.941, blue: 0.945) // Light slate
// Custom
case "General":                    return Color(red: 0.961, green: 0.961, blue: 0.961) // Light gray
```

In `categoryTextColor(_:)`, add before `default`:

```swift
// Pharmacy
case "Prescriptions":              return Color(red: 0.082, green: 0.396, blue: 0.753) // Blue
case "Over-the-Counter":           return Color(red: 0.369, green: 0.208, blue: 0.694) // Purple
case "Vitamins & Supplements":     return Color(red: 0.337, green: 0.545, blue: 0.184) // Green
case "First Aid":                  return Color(red: 0.776, green: 0.157, blue: 0.157) // Red
case "Personal Care (Pharmacy)":   return Color(red: 0.533, green: 0.176, blue: 0.455) // Pink
case "Baby":                       return Color(red: 0.012, green: 0.388, blue: 0.616) // Cyan
// Event
case "Drinks":                     return Color(red: 0.369, green: 0.208, blue: 0.694) // Indigo
case "Food":                       return Color(red: 0.929, green: 0.424, blue: 0.0)   // Orange
case "Decorations":                return Color(red: 0.698, green: 0.494, blue: 0.0)   // Amber
case "Tableware":                  return Color(red: 0.263, green: 0.388, blue: 0.424) // Slate
case "Activities":                 return Color(red: 0.427, green: 0.349, blue: 0.196) // Tan
// DIY Project
case "Tools":                      return Color(red: 0.263, green: 0.388, blue: 0.424) // Slate
case "Electrical":                 return Color(red: 0.698, green: 0.494, blue: 0.0)   // Amber
case "Plumbing":                   return Color(red: 0.082, green: 0.396, blue: 0.753) // Blue
case "Paint":                      return Color(red: 0.369, green: 0.208, blue: 0.694) // Purple
case "Garden":                     return Color(red: 0.337, green: 0.545, blue: 0.184) // Green
case "Lumber":                     return Color(red: 0.427, green: 0.349, blue: 0.196) // Tan
case "Fasteners":                  return Color(red: 0.263, green: 0.388, blue: 0.424) // Slate
// Custom
case "General":                    return Color(red: 0.459, green: 0.459, blue: 0.459) // Gray
```

- [ ] **Step 2: Build to verify no compilation errors**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Theme/SoftSageTheme.swift
git commit -m "feat: add category colors for pharmacy, event, DIY, and custom categories"
```

---

## Task 5: ListService Updates

**Files:**
- Modify: `ShoppingList/Services/ListService.swift`

- [ ] **Step 1: Update `createList` to accept type and eventDate**

In `ListService.swift`, replace the `createList(name:)` method (lines 48-65) with:

```swift
func createList(name: String, type: ListType = .groceries, eventDate: Date? = nil) async throws -> String {
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
        inviteCode: String(inviteCode),
        type: type,
        eventDate: eventDate
    )

    let docRef = try db.collection("lists").addDocument(from: list)
    return docRef.documentID
}
```

- [ ] **Step 2: Add `setDefaultList` and `archiveList` methods**

Add before the `// MARK: - Static helpers` section (before line 113):

```swift
func setDefaultList(_ listId: String) async throws {
    guard let userId = Auth.auth().currentUser?.uid else {
        throw ListServiceError.notAuthenticated
    }
    try await db.collection("users").document(userId).updateData([
        "defaultListId": listId
    ])
}

func archiveList(_ listId: String, archived: Bool) async throws {
    try await db.collection("lists").document(listId).updateData([
        "isArchived": archived,
        "updatedAt": FieldValue.serverTimestamp()
    ])
}
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add ShoppingList/Services/ListService.swift
git commit -m "feat: add list type to createList, add setDefaultList and archiveList methods"
```

---

## Task 6: AuthService Sign-Up Flow

**Files:**
- Modify: `ShoppingList/Services/AuthService.swift`

- [ ] **Step 1: Update `createUserDocumentIfNeeded` to create default Groceries list**

Replace the `createUserDocumentIfNeeded` method (lines 72-90) in `AuthService.swift`:

```swift
private func createUserDocumentIfNeeded(_ user: FirebaseAuth.User) async throws {
    let db = Firestore.firestore()
    let docRef = db.collection("users").document(user.uid)
    let doc = try await docRef.getDocument()

    if !doc.exists {
        // Create default Groceries list
        let inviteCode = UUID().uuidString.prefix(8).lowercased()
        let groceriesList = ShoppingList(
            name: String(localized: "Groceries"),
            ownerId: user.uid,
            memberIds: [user.uid],
            createdAt: Date(),
            updatedAt: Date(),
            inviteCode: String(inviteCode),
            type: .groceries
        )

        let listRef = db.collection("lists").document()
        let batch = db.batch()

        // Write user doc with defaultListId pointing to the new list
        let appUser = AppUser(
            displayName: user.displayName ?? "User",
            email: user.email ?? "",
            photoURL: user.photoURL?.absoluteString,
            createdAt: Date(),
            lastActiveAt: Date(),
            defaultListId: listRef.documentID,
            settings: AppUser.UserSettings()
        )
        try batch.setData(from: appUser, forDocument: docRef)
        try batch.setData(from: groceriesList, forDocument: listRef)

        try await batch.commit()
    } else {
        try await docRef.updateData(["lastActiveAt": FieldValue.serverTimestamp()])
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Services/AuthService.swift
git commit -m "feat: auto-create Groceries list and set defaultListId on sign-up"
```

---

## Task 7: CreateListView Redesign

**Files:**
- Modify: `ShoppingList/Views/Lists/CreateListView.swift`

- [ ] **Step 1: Redesign with type chips, event date picker, and primary toggle**

Replace `ShoppingList/Views/Lists/CreateListView.swift`:

```swift
import SwiftUI

struct CreateListView: View {
    @EnvironmentObject var listService: ListService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedType: ListType = .groceries
    @State private var eventDate = Date()
    @State private var setAsPrimary = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.paddingLarge) {
                    // Name field
                    VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                        Text("List Name")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .textCase(.uppercase)
                        TextField("List name", text: $name)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.divider, lineWidth: 1)
                            )
                    }

                    // Type chips
                    VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                        Text("Type")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .textCase(.uppercase)
                        FlowLayout(spacing: 8) {
                            ForEach(ListType.allCases) { type in
                                typeChip(type)
                            }
                        }
                    }

                    // Event date picker (conditional)
                    if selectedType == .event {
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Event Date")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)
                            DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    // Set as primary toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set as Primary")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Shows prominently on home screen")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: $setAsPrimary)
                            .tint(Theme.primaryGreen)
                            .labelsHidden()
                    }
                    .padding(Theme.paddingMedium)
                    .background(Theme.surfaceWhite)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.divider, lineWidth: 1)
                    )

                    // Create button
                    Button {
                        Task { await createList() }
                    } label: {
                        Text("Create List")
                            .font(Theme.headlineFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Theme.primaryGreen)
                            .cornerRadius(12)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating ? 0.5 : 1)
                }
                .padding(Theme.paddingMedium)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func typeChip(_ type: ListType) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isSelected ? type.themeColor.opacity(0.15) : Theme.surfaceWhite)
            .foregroundColor(isSelected ? type.themeColor : Theme.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? type.themeColor : Theme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel(type.displayName)
    }

    private func createList() async {
        isCreating = true
        let eventDateValue = selectedType == .event ? eventDate : nil
        if let listId = try? await listService.createList(name: name, type: selectedType, eventDate: eventDateValue) {
            if setAsPrimary {
                try? await listService.setDefaultList(listId)
            }
        }
        dismiss()
    }
}

/// Simple flow layout that wraps chips to next line
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x - spacing)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Views/Lists/CreateListView.swift
git commit -m "feat: redesign CreateListView with type chips, event date picker, and primary toggle"
```

---

## Task 8: PrimaryListCardView

**Files:**
- Create: `ShoppingList/Views/Lists/PrimaryListCardView.swift`

- [ ] **Step 1: Create the hero card view**

Create `ShoppingList/Views/Lists/PrimaryListCardView.swift`:

```swift
import SwiftUI

struct PrimaryListCardView: View {
    let list: ShoppingList
    let itemCount: Int
    let categoryCounts: [(ItemCategory, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Type icon + Primary badge
            HStack(spacing: 8) {
                Image(systemName: list.type.icon)
                    .font(.system(size: 20))
                Text("Primary")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.25))
                    .cornerRadius(10)
            }

            // List name
            Text(list.name)
                .font(.system(size: 18, weight: .bold, design: .rounded))

            // Meta info
            Text("\(itemCount) items \u{00B7} Updated \(list.updatedAt.relativeDescription)")
                .font(.system(size: 12))
                .opacity(0.85)

            // Category preview chips
            if !categoryCounts.isEmpty {
                HStack(spacing: 6) {
                    let visible = categoryCounts.prefix(2)
                    let remaining = itemCount - visible.reduce(0) { $0 + $1.1 }

                    ForEach(Array(visible), id: \.0) { category, count in
                        Text("\(count) \(category.rawValue)")
                            .font(.system(size: 10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2))
                            .cornerRadius(8)
                    }

                    if remaining > 0 {
                        Text("+\(remaining) more")
                            .font(.system(size: 10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.49, blue: 0.196),  // #2E7D32
                    Color(red: 0.22, green: 0.557, blue: 0.235)  // #388E3C
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(red: 0.18, green: 0.49, blue: 0.196).opacity(0.3), radius: 12, y: 4)
        .accessibilityLabel("Primary list: \(list.name), \(itemCount) items")
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Views/Lists/PrimaryListCardView.swift
git commit -m "feat: add PrimaryListCardView hero card with gradient and category chips"
```

---

## Task 9: Update ListCardView

**Files:**
- Modify: `ShoppingList/Views/Lists/ListCardView.swift`

- [ ] **Step 1: Add type icon and dimmed state**

Replace `ShoppingList/Views/Lists/ListCardView.swift`:

```swift
import SwiftUI

struct ListCardView: View {
    let list: ShoppingList
    let itemCount: Int

    var body: some View {
        HStack(spacing: Theme.paddingMedium) {
            // Type icon
            Image(systemName: list.type.icon)
                .font(.system(size: 16))
                .foregroundColor(list.type.themeColor)
                .frame(width: 32, height: 32)
                .background(list.type.themeColor.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    Text("\(itemCount) items")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    if list.isPastEvent {
                        Text("\u{00B7} Past event")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    } else if let eventDate = list.eventDate, list.type == .event {
                        Text("\u{00B7} \(eventDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
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
        .opacity(list.isPastEvent ? 0.5 : 1.0)
        .accessibilityLabel(list.isPastEvent ? "\(list.name), past event" : list.name)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Views/Lists/ListCardView.swift
git commit -m "feat: add type icon and past-event dimming to ListCardView"
```

---

## Task 10: ListsTabView Redesign

**Files:**
- Modify: `ShoppingList/Views/Lists/ListsTabView.swift`

- [ ] **Step 1: Split into primary/other/archived sections**

Replace `ShoppingList/Views/Lists/ListsTabView.swift`:

```swift
import SwiftUI

struct ListsTabView: View {
    @EnvironmentObject var listService: ListService
    @EnvironmentObject var authService: AuthService
    @State private var showCreateList = false
    @StateObject private var primaryItemService = ItemService()
    @State private var showArchived = false

    private var primaryList: ShoppingList? {
        guard let userId = authService.user?.uid else { return nil }
        // First try to find by defaultListId stored on user
        // Fallback: find the first groceries list owned by the user
        if let defaultId = userDefaultListId,
           let list = listService.lists.first(where: { $0.id == defaultId && !$0.isArchived }) {
            return list
        }
        return listService.lists.first(where: { $0.type == .groceries && $0.ownerId == userId && !$0.isArchived })
    }

    private var otherLists: [ShoppingList] {
        listService.lists.filter { !$0.isArchived && $0.id != primaryList?.id }
    }

    private var archivedLists: [ShoppingList] {
        listService.lists.filter { $0.isArchived }
    }

    // User's defaultListId fetched from Firestore
    @State private var userDefaultListId: String?

    private var primaryCategoryCounts: [(ItemCategory, Int)] {
        let active = primaryItemService.activeItems
        let grouped = Dictionary(grouping: active) { $0.resolvedCategory }
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.paddingSmall) {
                    // Primary list hero card
                    if let primary = primaryList {
                        NavigationLink(value: primary) {
                            PrimaryListCardView(
                                list: primary,
                                itemCount: primaryItemService.activeItems.count,
                                categoryCounts: primaryCategoryCounts
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Other lists section
                    if !otherLists.isEmpty {
                        SectionHeader(title: "Other Lists")

                        ForEach(otherLists) { list in
                            NavigationLink(value: list) {
                                ListCardView(list: list, itemCount: 0)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Archived section (collapsible)
                    if !archivedLists.isEmpty {
                        Button {
                            withAnimation { showArchived.toggle() }
                        } label: {
                            HStack {
                                Text("Archived")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.top, Theme.paddingMedium)
                            .padding(.horizontal, 4)
                        }

                        if showArchived {
                            ForEach(archivedLists) { list in
                                NavigationLink(value: list) {
                                    ListCardView(list: list, itemCount: 0)
                                        .opacity(0.5)
                                }
                                .buttonStyle(.plain)
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
            .onAppear {
                fetchDefaultListId()
            }
            .onChange(of: primaryList?.id) { _, newId in
                // Subscribe to primary list's items for category counts
                primaryItemService.stopListening()
                if let listId = newId {
                    primaryItemService.startListening(listId: listId)
                }
            }
        }
    }

    private func fetchDefaultListId() {
        guard let userId = authService.user?.uid else { return }
        Task {
            userDefaultListId = try? await ListService.fetchUserDefaultListId(for: userId)
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.top, Theme.paddingMedium)
        .padding(.horizontal, 4)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED. Note: `ListsTabView` now depends on `authService` via `@EnvironmentObject`. Verify `ContentView` (or wherever `ListsTabView` is used) already injects `AuthService` as an environment object. If not, you'll get a runtime crash — check and add `.environmentObject(authService)` if missing.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Views/Lists/ListsTabView.swift
git commit -m "feat: redesign ListsTabView with primary hero card, other lists, and archived section"
```

---

## Task 11: ListSettings — Set as Primary & Archive

**Files:**
- Modify: `ShoppingList/Views/Settings/ListSettingsView.swift`

- [ ] **Step 1: Add "Set as Primary" and "Archive" options**

In `ListSettingsView.swift`, add two new sections after the "Members" section (after line 69, before the `if isOwner` block):

```swift
Section {
    Button {
        Task {
            try? await listService.setDefaultList(list.id ?? "")
            dismiss()
        }
    } label: {
        Label("Set as Primary", systemImage: "star.fill")
    }
}

Section {
    Button {
        Task {
            try? await listService.archiveList(list.id ?? "", archived: !list.isArchived)
            dismiss()
        }
    } label: {
        Label(
            list.isArchived ? "Unarchive List" : "Archive List",
            systemImage: list.isArchived ? "tray.and.arrow.up" : "archivebox"
        )
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingList/Views/Settings/ListSettingsView.swift
git commit -m "feat: add Set as Primary and Archive/Unarchive options to list settings"
```

---

## Task 12: Cloud Function — Type-Aware Categories

**Files:**
- Create: `functions/src/categories.ts`
- Create: `functions/test/categories.test.ts`
- Modify: `functions/src/gemini.ts`
- Modify: `functions/src/parseInput.ts`

- [ ] **Step 1: Write the failing test for category mapping**

Create `functions/test/categories.test.ts`:

```typescript
import { getCategoriesForListType } from "../src/categories";

describe("getCategoriesForListType", () => {
  it("returns grocery categories for 'groceries'", () => {
    const categories = getCategoriesForListType("groceries");
    expect(categories).toContain("Produce");
    expect(categories).toContain("Dairy");
    expect(categories).toContain("Other");
    expect(categories).not.toContain("Prescriptions");
  });

  it("returns pharmacy categories for 'pharmacy'", () => {
    const categories = getCategoriesForListType("pharmacy");
    expect(categories).toContain("Prescriptions");
    expect(categories).toContain("Over-the-Counter");
    expect(categories).toContain("Other");
    expect(categories).not.toContain("Produce");
  });

  it("returns event categories for 'event'", () => {
    const categories = getCategoriesForListType("event");
    expect(categories).toContain("Drinks");
    expect(categories).toContain("Decorations");
    expect(categories).toContain("Other");
  });

  it("returns DIY categories for 'diyProject'", () => {
    const categories = getCategoriesForListType("diyProject");
    expect(categories).toContain("Tools");
    expect(categories).toContain("Lumber");
    expect(categories).toContain("Other");
  });

  it("returns generic categories for 'custom'", () => {
    const categories = getCategoriesForListType("custom");
    expect(categories).toContain("General");
    expect(categories).toContain("Other");
  });

  it("falls back to grocery categories for undefined type", () => {
    const categories = getCategoriesForListType(undefined);
    expect(categories).toContain("Produce");
    expect(categories).toContain("Dairy");
  });

  it("falls back to grocery categories for unknown type string", () => {
    const categories = getCategoriesForListType("unknown");
    expect(categories).toContain("Produce");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern=categories 2>&1 | tail -20`

Expected: FAIL — module `../src/categories` not found.

- [ ] **Step 3: Create the categories module**

Create `functions/src/categories.ts`:

```typescript
const GROCERY_CATEGORIES = [
  "Produce", "Dairy", "Meat", "Bakery", "Frozen",
  "Beverages", "Snacks", "Pantry", "Household", "Personal Care", "Other",
] as const;

const PHARMACY_CATEGORIES = [
  "Prescriptions", "Over-the-Counter", "Vitamins & Supplements",
  "First Aid", "Personal Care (Pharmacy)", "Baby", "Other",
] as const;

const EVENT_CATEGORIES = [
  "Drinks", "Food", "Decorations", "Tableware", "Activities", "Other",
] as const;

const DIY_CATEGORIES = [
  "Tools", "Electrical", "Plumbing", "Paint", "Garden", "Lumber", "Fasteners", "Other",
] as const;

const CUSTOM_CATEGORIES = [
  "General", "Other",
] as const;

const CATEGORY_MAP: Record<string, readonly string[]> = {
  groceries: GROCERY_CATEGORIES,
  pharmacy: PHARMACY_CATEGORIES,
  event: EVENT_CATEGORIES,
  diyProject: DIY_CATEGORIES,
  custom: CUSTOM_CATEGORIES,
};

export function getCategoriesForListType(listType: string | undefined): readonly string[] {
  if (!listType || !(listType in CATEGORY_MAP)) {
    return GROCERY_CATEGORIES;
  }
  return CATEGORY_MAP[listType];
}

// Re-export for backward compatibility
export const CATEGORIES = GROCERY_CATEGORIES;
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd functions && npm test -- --testPathPattern=categories 2>&1 | tail -20`

Expected: All tests PASS.

- [ ] **Step 5: Update `gemini.ts` to import from `categories.ts`**

In `functions/src/gemini.ts`, replace the `CATEGORIES` export (lines 23-26):

```typescript
// Re-export CATEGORIES from categories module for backward compatibility
export { CATEGORIES } from "./categories";
```

Remove the old `CATEGORIES` constant.

- [ ] **Step 6: Update `parseInput.ts` to read list type and use type-specific categories**

In `functions/src/parseInput.ts`:

First, add the import at the top (after existing imports):

```typescript
import { getCategoriesForListType } from "./categories";
```

Then update `parseRawInput` signature (line 17) to accept categories:

```typescript
export async function parseRawInput(rawInput: string, language: string = "en", categories?: readonly string[]): Promise<ParsedItem[]> {
```

And update the prompt to use the passed categories (replace the `CATEGORIES.join(", ")` reference on line 25):

```typescript
const categoryList = categories || getCategoriesForListType(undefined);
```

And in the prompt string, replace `${CATEGORIES.join(", ")}` with `${categoryList.join(", ")}`.

Then update `onItemCreated` to read the list type before parsing. In the trigger handler, after getting `listId` (line 62), add:

```typescript
// Read list type for category mapping
const listDoc = await db.collection("lists").doc(listId).get();
const listType = listDoc.data()?.type as string | undefined;
const categories = getCategoriesForListType(listType);
```

And pass `categories` to `parseRawInput` (line 66):

```typescript
const parsedItems = await parseRawInput(rawInput, language, categories);
```

- [ ] **Step 7: Run all Cloud Function tests**

Run: `cd functions && npm test 2>&1 | tail -30`

Expected: All tests PASS. The existing `parseInput.test.ts` mock already includes `CATEGORIES` in its mock — it should still work since we re-export from `categories.ts`.

- [ ] **Step 8: Build Cloud Functions**

Run: `cd functions && npm run build 2>&1 | tail -10`

Expected: Compiles without errors.

- [ ] **Step 9: Commit**

```bash
git add functions/src/categories.ts functions/test/categories.test.ts functions/src/gemini.ts functions/src/parseInput.ts
git commit -m "feat: add per-list-type category mapping for Gemini item parsing"
```

---

## Task 13: UI Tests

**Files:**
- Modify: `ShoppingListUITests/ShoppingListUITests.swift`

- [ ] **Step 1: Update `createListIfNeeded` helper to accept type**

**Important:** The redesigned `CreateListView` uses "Create List" / "Opret liste" as the button label (previously "Create" / "Opret"). Update the existing `testCreateList` test (line 30) to use the new label too: change `tapButton(englishLabel: "Create", danishLabel: "Opret")` to `tapButton(englishLabel: "Create List", danishLabel: "Opret liste")`.

In `ShoppingListUITests.swift`, replace the `createListIfNeeded(name:)` helper (lines 320-337):

```swift
private func createListIfNeeded(name: String, type: String? = nil) {
    let listCell = app.staticTexts[name]
    if listCell.waitForExistence(timeout: 3) {
        return
    }

    let addButton = app.navigationBars.buttons["plus"]
    guard addButton.waitForExistence(timeout: 5) else { return }
    addButton.tap()

    let nameField = app.textFields.firstMatch
    guard nameField.waitForExistence(timeout: 5) else { return }
    nameField.tap()
    nameField.typeText(name)

    // Select type chip if specified
    if let type {
        let typeChip = app.buttons[type]
        if typeChip.waitForExistence(timeout: 3) {
            typeChip.tap()
        }
    }

    tapButton(englishLabel: "Create List", danishLabel: "Opret liste")

    XCTAssertTrue(listCell.waitForExistence(timeout: 10))
}
```

- [ ] **Step 2: Add list type creation tests**

Add these tests after the existing `testAddItemToList` test:

```swift
// MARK: - List Types

func testCreateGroceryList() throws {
    signInIfNeeded()

    let addButton = app.navigationBars.buttons["plus"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    addButton.tap()

    // Groceries should be selected by default
    let groceriesChip = app.buttons["Groceries"]
    XCTAssertTrue(groceriesChip.waitForExistence(timeout: 3))

    let nameField = app.textFields.firstMatch
    nameField.tap()
    nameField.typeText("Test Grocery List")

    tapButton(englishLabel: "Create List", danishLabel: "Opret liste")

    let listCell = app.staticTexts["Test Grocery List"]
    XCTAssertTrue(listCell.waitForExistence(timeout: 10))
}

func testCreatePharmacyList() throws {
    signInIfNeeded()

    let addButton = app.navigationBars.buttons["plus"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    addButton.tap()

    let pharmacyChip = app.buttons["Pharmacy"]
    XCTAssertTrue(pharmacyChip.waitForExistence(timeout: 3))
    pharmacyChip.tap()

    let nameField = app.textFields.firstMatch
    nameField.tap()
    nameField.typeText("My Pharmacy")

    tapButton(englishLabel: "Create List", danishLabel: "Opret liste")

    let listCell = app.staticTexts["My Pharmacy"]
    XCTAssertTrue(listCell.waitForExistence(timeout: 10))
}

func testCreateEventListShowsDatePicker() throws {
    signInIfNeeded()

    let addButton = app.navigationBars.buttons["plus"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    addButton.tap()

    // Date picker should NOT be visible initially
    let datePickerPredicate = NSPredicate(format: "label CONTAINS[c] 'Event Date'")
    let datePicker = app.descendants(matching: .any).matching(datePickerPredicate).firstMatch
    XCTAssertFalse(datePicker.exists, "Date picker should not show for non-event type")

    // Tap Event chip
    let eventChip = app.buttons["Party / Event"]
    XCTAssertTrue(eventChip.waitForExistence(timeout: 3))
    eventChip.tap()

    // Date picker should appear
    sleep(1)
    let datePickerAfter = app.datePickers.firstMatch
    XCTAssertTrue(datePickerAfter.waitForExistence(timeout: 3), "Date picker should appear for event type")

    // Tap Groceries — date picker should disappear
    app.buttons["Groceries"].tap()
    sleep(1)
    XCTAssertFalse(app.datePickers.firstMatch.exists, "Date picker should hide for non-event type")

    // Cancel
    tapButton(englishLabel: "Cancel", danishLabel: "Annuller")
}

// MARK: - Primary List

func testDefaultPrimaryListIsGroceries() throws {
    signInIfNeeded()
    sleep(3)

    // The Primary badge should be visible on the home screen
    let primaryBadge = NSPredicate(format: "label CONTAINS[c] 'Primary'")
    let badge = app.descendants(matching: .any).matching(primaryBadge).firstMatch
    XCTAssertTrue(badge.waitForExistence(timeout: 5), "Primary list badge should appear on home screen")
}

func testSetAsPrimaryFromListSettings() throws {
    signInIfNeeded()
    createListIfNeeded(name: "New Primary Test", type: "Pharmacy")

    // Open the list
    let listCell = app.staticTexts["New Primary Test"]
    XCTAssertTrue(listCell.waitForExistence(timeout: 10))
    listCell.tap()

    // Open settings menu
    app.navigationBars.buttons["ellipsis.circle"].tap()
    tapButton(englishLabel: "List Settings", danishLabel: "Listeindstillinger")
    sleep(1)

    // Tap Set as Primary
    let setPrimary = app.buttons["Set as Primary"]
    XCTAssertTrue(setPrimary.waitForExistence(timeout: 3))
    setPrimary.tap()
    sleep(2)

    // Navigate back to home screen
    app.navigationBars.buttons.firstMatch.tap()
    sleep(2)

    // The hero card should now show "New Primary Test"
    let heroPredicate = NSPredicate(format: "label CONTAINS[c] 'New Primary Test' AND label CONTAINS[c] 'Primary'")
    let heroCard = app.descendants(matching: .any).matching(heroPredicate).firstMatch
    XCTAssertTrue(heroCard.waitForExistence(timeout: 5), "New Primary Test should be the hero card")
}

// MARK: - Archive

func testArchiveList() throws {
    signInIfNeeded()
    createListIfNeeded(name: "Archive Test List", type: "Pharmacy")

    // Open the list
    app.staticTexts["Archive Test List"].tap()
    sleep(1)

    // Open settings
    app.navigationBars.buttons["ellipsis.circle"].tap()
    tapButton(englishLabel: "List Settings", danishLabel: "Listeindstillinger")
    sleep(1)

    // Tap Archive
    let archiveBtn = app.buttons["Archive List"]
    XCTAssertTrue(archiveBtn.waitForExistence(timeout: 3))
    archiveBtn.tap()
    sleep(2)

    // Navigate back
    tapTab(englishLabel: "Lists", danishLabel: "Lister")
    sleep(2)

    // The list should be under Archived section
    let archivedHeader = app.staticTexts["Archived"]
    XCTAssertTrue(archivedHeader.waitForExistence(timeout: 5), "Archived section should appear")
}
```

- [ ] **Step 2: Build the UI test target**

Run: `xcodebuild build-for-testing -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ShoppingListUITests/ShoppingListUITests.swift
git commit -m "feat: add UI tests for list type creation, primary list, and archiving"
```

---

## Task 14: XcodeGen Regenerate & Final Build

**Files:**
- Modify: `project.yml` (if new files aren't auto-discovered)

- [ ] **Step 1: Regenerate Xcode project**

Run: `cd /Users/tgjerm01/Programming/shopping-list-app && xcodegen generate 2>&1`

Expected: "Project generated" or similar success message. XcodeGen auto-discovers Swift files from the directory structure, so the new files (`ListType.swift`, `PrimaryListCardView.swift`, `categories.ts`, etc.) should be picked up automatically.

- [ ] **Step 2: Full build**

Run: `xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run all unit tests**

Run: `xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests -quiet 2>&1 | tail -20`

Expected: All unit tests PASS.

- [ ] **Step 4: Run Cloud Function tests**

Run: `cd functions && npm test 2>&1 | tail -20`

Expected: All Cloud Function tests PASS.

- [ ] **Step 5: Commit if any project.yml changes were needed**

```bash
git add project.yml ShoppingList.xcodeproj
git commit -m "chore: regenerate Xcode project with new list type files"
```
