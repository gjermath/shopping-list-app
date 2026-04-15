# List Types & Primary List Design

## Summary

Add a type system to shopping lists so the app supports purpose-built lists (Groceries, Pharmacy, Party/Event, DIY Project, Custom) with per-type item categories. One list is designated as the user's "primary" list and gets prominent hero-card treatment on the home screen.

## Goals

- Give each list a purpose-specific identity with its own icon, color, and item categories
- Make the primary list (default: Groceries) visually dominant on the home screen
- Support event lists with optional dates that dim when past
- Allow any list to be archived when no longer active
- Keep backward compatibility — existing lists seamlessly become Groceries type

## Non-Goals

- Server-side list type definitions (Remote Config, Firestore-based type registry)
- Cross-list item sharing or moving items between lists
- Per-type custom icons or colors chosen by the user (predefined set only)

---

## Data Model

### ListType Enum

New `ListType` enum (String, Codable, CaseIterable):

| Case | Display Name | Icon (SF Symbol) | Item Categories |
|------|-------------|-------------------|-----------------|
| `.groceries` | Groceries | `cart.fill` | Produce, Dairy, Meat, Bakery, Frozen, Beverages, Snacks, Pantry, Household, Personal Care, Other |
| `.pharmacy` | Pharmacy | `cross.case.fill` | Prescriptions, Over-the-Counter, Vitamins & Supplements, First Aid, Personal Care, Baby, Other |
| `.event` | Party / Event | `party.popper.fill` | Drinks, Food, Decorations, Tableware, Activities, Other |
| `.diyProject` | DIY Project | `hammer.fill` | Tools, Electrical, Plumbing, Paint, Garden, Lumber, Fasteners, Other |
| `.custom` | Custom | `list.bullet` | General, Other |

Each case provides: `displayName`, `icon`, `themeColor`, and `itemCategories: [ItemCategory]`.

**Theme colors per type** (used as accent on compact list cards — icon background tint, subtle left border):

| Type | Color | Hex |
|------|-------|-----|
| Groceries | Primary Green | `#2E7D32` |
| Pharmacy | Soft Blue | `#1565C0` |
| Event | Warm Amber | `#EF6C00` |
| DIY Project | Slate Teal | `#43636C` |
| Custom | Neutral Gray | `#757575` |

These complement the existing Soft Sage palette. The primary list hero card always uses the brand green gradient regardless of list type.

### ShoppingList Model Changes

New fields on `ShoppingList`:

- `type: ListType` — defaults to `.groceries`. Existing lists without this field decode as `.groceries`.
- `eventDate: Date?` — only meaningful for `.event` lists, `nil` for all others.
- `isArchived: Bool` — defaults to `false`. Existing lists without this field decode as `false`.

### AppUser Model Changes

The existing `defaultListId: String?` field gets activated. It points to the user's primary list. Set automatically to the Groceries list created at sign-up. User can change it to any list they're a member of (including shared lists).

### ItemCategory Expansion

The existing `ItemCategory` enum gains new cases for non-grocery list types:

- **Pharmacy:** `prescriptions`, `overTheCounter`, `vitaminsSupplements`, `firstAid`, `personalCarePharmacy`, `baby`
- **Event:** `drinks`, `food`, `decorations`, `tableware`, `activities`
- **DIY Project:** `tools`, `electrical`, `plumbing`, `paint`, `garden`, `lumber`, `fasteners`
- **Custom:** `general`

Existing grocery cases remain unchanged. A static method `ItemCategory.categories(for listType: ListType) -> [ItemCategory]` returns the correct subset.

`SoftSageTheme.swift` gets `categoryColor` and `categoryTextColor` entries for each new category case.

### Firestore Structure

No structural changes. New fields on existing `/lists/{listId}` document:

```
/lists/{listId}
  type: String          // "groceries" | "pharmacy" | "event" | "diyProject" | "custom"
  eventDate: Timestamp? // only for event lists
  isArchived: Bool      // default false
```

No new indexes required. Existing `memberIds (CONTAINS) + updatedAt (DESC)` covers the home screen query. Filtering by `isArchived` and sorting primary-first happen client-side.

---

## UI Design

### Home Screen (ListsTabView)

The home screen retains its list-of-all-lists structure but reorganizes into sections:

1. **Primary list** — large gradient hero card in brand green (`#2E7D32` → `#388E3C`). Shows type icon, "Primary" badge, item count, member count, last updated, and category preview chips (e.g., "3 Produce", "2 Dairy", "+7 more"). The category chips require per-category item counts — `ListsTabView` will subscribe to the primary list's items (via `ItemService`) to compute these counts. This is a lightweight query since only the primary list needs this detail; other lists show only total item count.
2. **"Other Lists" section** — compact row cards with type icon, name, item count, and last updated. Event lists with past dates render at 0.5 opacity with "Past event" label.
3. **"Archived" section** — collapsible, at the bottom. Archived lists shown at reduced opacity with "Archived" label.

### Create List Screen

Single-screen sheet (replaces existing `CreateListView`):

- **Name field** — text input at the top
- **Type chips** — horizontal wrap of pill-shaped buttons (icon + label). Selected chip gets green fill and border. Selecting "Event" conditionally shows a date picker below.
- **"Set as Primary" toggle** — switch with subtitle "Shows prominently on home screen". Off by default.
- **"Create List" button** — green CTA at the bottom

### List Settings

Add to existing list settings menu on `ListDetailView`:

- **"Set as Primary"** option — available on any list the user is a member of. Updates `defaultListId` on user doc.
- **"Archive List"** / **"Unarchive List"** — toggles `isArchived`.

### Archived/Dimmed States

- **Past event lists:** `opacity(0.5)` on the home screen card. Date label replaced with "Past event". Not auto-archived — user decides.
- **Archived lists:** moved to collapsible "Archived" section at bottom of home screen. Can be unarchived from list settings.
- **Conflict rule:** if a past-event list is also the primary list, primary treatment wins (no dimming).

---

## Sign-Up & Default Primary List

After successful account creation, `AuthService` performs a Firestore batch write:

1. Creates the user document (`/users/{userId}`)
2. Creates a "Groceries" list (`/lists/{listId}`) with `type: .groceries` and the user as owner/member
3. Sets `defaultListId` on the user doc to the new list's ID

The user lands on the home screen with their primary Groceries list already showing as the hero card.

### Changing Primary

- Via "Set as Primary" in list settings on any `ListDetailView`
- Via the toggle on the Create List screen
- Updates `defaultListId` on user doc. Only one primary at a time — setting a new one replaces the old one.

### Siri / App Intents

`AddItemsIntent` defaults to adding items to the user's primary list via `ListService.fetchUserDefaultListId(for:)`. This path already partially exists but now has a real default to point to.

---

## Cloud Function Changes

### `onItemCreated`

The function needs to read the parent list's `type` field to determine which categories to pass to Gemini for item parsing.

- Read `/lists/{listId}` to get `type`
- Map `type` to the corresponding category list
- Pass categories in the Gemini prompt: "Categorize this item into one of: [category1, category2, ...]"
- If `type` is missing (old list pre-migration), fall back to grocery categories

No new Cloud Functions needed.

---

## Migration & Backward Compatibility

- **Existing lists:** Decode without `type` field as `.groceries`, without `isArchived` as `false`, without `eventDate` as `nil`. No migration script needed.
- **Existing items:** Current categories are all valid grocery categories. New enum cases are additive — existing raw values remain stable.
- **Cloud Function:** Falls back to grocery categories if `type` is missing on the list document. No deployment ordering issues.
- **Firestore indexes:** No new indexes required.

---

## Testing Strategy

### Unit Tests

- `ListType` enum: verify `displayName`, `icon`, `itemCategories` for each case
- `ShoppingList` decoding: verify defaults for missing `type`, `isArchived`, `eventDate`
- `ItemCategory.categories(for:)`: verify correct subset returned per list type
- `AppUser.defaultListId`: verify it can be set and read

### UI Tests

Tests follow existing conventions: `signInIfNeeded()` for auth, bilingual label matching (EN/DA), predicate-based element queries, and `sleep()` for Firestore listener round-trips.

**Create List with Type Selection:**
- `testCreateGroceryList` — tap +, enter name, verify Groceries type chip is selected by default, tap Create, verify list appears on home screen with cart icon
- `testCreatePharmacyList` — tap +, enter name, tap Pharmacy chip, tap Create, verify list appears with pharmacy icon
- `testCreateEventListShowsDatePicker` — tap +, tap Event chip, verify a date picker appears. Tap a different type chip, verify date picker disappears. Tap Event again, verify it reappears.
- `testCreateDIYProjectList` — tap +, enter name, tap DIY Project chip, tap Create, verify list appears with hammer icon
- `testCreateCustomList` — tap +, enter name, tap Custom chip, tap Create, verify list appears

**Primary List Hero Card:**
- `testDefaultPrimaryListIsGroceries` — sign in fresh (new account), verify the auto-created Groceries list renders as the hero card (check for "Primary" badge via predicate matching)
- `testSetAsPrimaryFromCreateSheet` — create a new Pharmacy list with "Set as Primary" toggle on, verify it now renders as the hero card and the previous primary moves to the "Other Lists" section
- `testSetAsPrimaryFromListSettings` — open an existing non-primary list, tap settings menu, tap "Set as Primary", navigate back to home screen, verify that list is now the hero card

**Archive Flow:**
- `testArchiveList` — open a non-primary list's settings, tap "Archive List", navigate back to home screen, verify the list no longer appears in the main section but appears under a collapsible "Archived" section
- `testUnarchiveList` — with an archived list, expand the Archived section, tap the list, open settings, tap "Unarchive List", navigate back, verify it returns to the "Other Lists" section

**Event Date & Dimming:**
- `testPastEventListIsDimmed` — create an event list with a date in the past, navigate to home screen, verify the list card has reduced opacity (use `XCUIElement` value or accessibility trait to confirm dimmed state) and shows "Past event" label

**Per-Type Item Categories:**
- `testPharmacyListShowsPharmacyCategories` — create a Pharmacy list, open it, add an item (e.g., "Ibuprofen"), wait for Cloud Function categorization, verify category header is from the pharmacy set (e.g., "Over-the-Counter") rather than grocery categories
- `testDIYListShowsDIYCategories` — create a DIY Project list, open it, add "Screwdriver", verify category header is from the DIY set (e.g., "Tools")

**Helper Updates:**
- `createListIfNeeded(name:type:)` — extend existing helper to accept an optional `ListType` parameter, defaulting to `.groceries`. Taps the appropriate type chip before creating.

### Cloud Function Tests

- Parse item with each list type: verify correct categories in Gemini prompt
- Parse item on list without `type` field: verify grocery fallback
