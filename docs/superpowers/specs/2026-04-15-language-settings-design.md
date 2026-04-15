# Language Settings with Full Localization — Design Spec

## Overview

Add Danish and English language support with two levels of control:
1. **App-level language** — full UI localization (all strings, nav titles, buttons). Stored in user profile. Defaults to device language if Danish or English, otherwise English.
2. **Per-list language override** — affects AI item parsing language and category display names within that list. App chrome stays in the app language.

## Supported Languages

- English (`en`) — default fallback
- Danish (`da`)

## Data Model Changes

### `AppUser.UserSettings`

Add `language: String?` field. Values:
- `nil` — use device language (resolved to `da` or `en` at runtime; non-Danish devices → `en`)
- `"en"` — English
- `"da"` — Danish

### `ShoppingList`

Add `language: String?` field. Values:
- `nil` — inherit from app-level setting
- `"en"` — English (overrides app setting for this list)
- `"da"` — Danish (overrides app setting for this list)

### `Item`

Add `language: String` field. Set at creation time to the resolved language (list override > app setting > device). Persisted so the Cloud Function knows what language to parse in, regardless of who added the item or what their settings are.

## Language Resolution

Priority order (highest to lowest):
1. List's `language` field (if set)
2. User's `settings.language` field (if set)
3. Device language (if `da`, use `da`; otherwise `en`)

This resolution is used for:
- Setting the item's `language` field when adding items
- Displaying category names in list views
- Passing language to Cloud Functions

## App-Level Localization

### String Catalog

Create `Localizable.xcstrings` with all ~80 user-facing strings in English and Danish. Xcode's String Catalog format supports:
- Simple strings: `"My Lists"` → `"Mine Lister"`
- Interpolated strings: `"Completed (%lld)"` → `"Fuldført (%lld)"`
- Plurals where needed

### Locale Override

In `ShoppingListApp.swift`, apply `.environment(\.locale, resolvedLocale)` at the root. This makes all `Text("key")` views resolve against the String Catalog in the chosen language, without changing the device language.

When the user changes their language setting, the `@Published` property triggers a SwiftUI re-render with the new locale.

### App Intents / Siri

`AddItemsIntent` strings use `LocalizedStringResource` which respects the String Catalog automatically.

## Per-List Category Names

`ItemCategory` display names (emoji + label) are currently hardcoded in `SoftSageTheme.swift`. Change these to use localized strings. When rendering inside a list view, resolve the category name using the list's effective language.

The `CategorySectionView` receives the list's language and uses it to display category headers. This means a Danish user viewing an English-language list sees English category names ("Dairy") but Danish app chrome ("Indstillinger" for Settings).

## Cloud Function Changes

### `parseInput.ts`

The `onItemCreated` function reads the item's `language` field and includes it in the Gemini prompt:

```
Parse the following grocery items. The text is written in [Danish/English].
```

This ensures "mælk og brød" is correctly parsed as two items: "Mælk" (Dairy) and "Brød" (Bakery).

### Category mapping

The Cloud Function returns English category keys (`dairy`, `bakery`, etc.) regardless of input language. Client-side localization handles display names.

## Settings UI

### Profile Tab — App Language

Add a "Language" row in the Preferences section with a Picker:
- "Device Default" / "Enhedsstandard"
- "English"
- "Dansk"

Changing this updates `AppUser.settings.language` in Firestore and immediately re-renders the app in the new language.

### List Settings — List Language

Add a "Language" row with a Picker:
- "App Default" / "Appstandard" (inherits app setting)
- "English"
- "Dansk"

Changing this updates `ShoppingList.language` in Firestore.

## Files

### Create
- `ShoppingList/Resources/Localizable.xcstrings` — String Catalog with ~80 strings in en/da
- `ShoppingList/Services/LanguageService.swift` — resolves effective language (list > app > device), provides `Locale` for SwiftUI environment

### Modify
- `ShoppingList/Models/User.swift` — add `language` to `UserSettings`
- `ShoppingList/Models/ShoppingList.swift` — add `language: String?` field + CodingKeys
- `ShoppingList/Models/Item.swift` — add `language: String` field
- `ShoppingList/ShoppingListApp.swift` — apply `.environment(\.locale, ...)` from LanguageService
- `ShoppingList/Views/Settings/ProfileView.swift` — add language picker
- `ShoppingList/Views/Settings/ListSettingsView.swift` — add per-list language picker
- `ShoppingList/Views/ListDetail/CategorySectionView.swift` — resolve category name from list language
- `ShoppingList/Views/ListDetail/ListDetailView.swift` — pass language when adding items
- `ShoppingList/Models/ItemCategory.swift` — category `displayName` becomes a localized function
- `ShoppingList/Intents/AddItemsIntent.swift` — pass resolved language when adding items
- `functions/src/parseInput.ts` — use item's `language` field in Gemini prompt
- All view files — replace hardcoded strings with localized keys (~25 files)

## What Stays the Same

- Firestore rules — no language-based access control
- Firestore indexes — no queries filter by language
- Storage rules — unchanged
- Firebase project config — unchanged
