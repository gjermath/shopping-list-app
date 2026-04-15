# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Generate Xcode project (required after changing project.yml)
xcodegen generate

# Build
xcodebuild build -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet

# Run all unit tests
xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListTests

# Run all UI tests
xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListUITests

# Run a single UI test
xcodebuild test -scheme ShoppingList -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShoppingListUITests/ShoppingListUITests/testCreateList

# Cloud Functions (run from functions/ directory)
cd functions && npm run build       # TypeScript -> lib/
cd functions && npm test            # Jest tests
cd functions && npm run serve       # Local emulator
cd functions && npm run deploy      # Deploy functions only

# Firebase deploy
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage
firebase deploy --only functions
```

## Architecture

SwiftUI app (iOS 17+) with Firebase backend and Gemini AI Cloud Functions. XcodeGen-managed project (`project.yml`).

### Service Layer Pattern

All services are `@MainActor` `ObservableObject` classes exposed via `@EnvironmentObject`. Two categories:

**Listener-based** (real-time Firestore sync, started in `onAppear`, stopped in `onDisappear`):
- `ListService` — lists where user is a member
- `ItemService` — items subcollection for a specific list

**Static/one-shot** (for use outside UI lifecycle, e.g., App Intents):
- `ListService.fetchLists(for:)`, `ListService.fetchUserDefaultListId(for:)`
- `ItemService.addItemDirectly(listId:rawInput:userId:source:)`

**Stateless services** (called directly, no listener):
- `AIService` — wraps Cloud Function calls (parseImage, suggestFrequentItems, reviewDuplicates)
- `PhotoService` — uploads images to Firebase Storage
- `SpeechService` — on-device voice recognition
- `HistoryService` — records item actions, queries purchase frequency
- `InviteService` — generates invite links
- `NetworkMonitor` — NWPathMonitor wrapper

### Item Creation Pipeline

1. Client writes item with `rawInput` to Firestore
2. `onItemCreated` Cloud Function triggers, sends text to Gemini 2.0 Flash
3. If Gemini parses multiple items: batch-delete original, create new docs
4. If single item: update original with parsed name/quantity/category
5. Firestore listener on client auto-reflects changes

### Auth Flow

`ShoppingListApp` renders a loading → signed-in → sign-out state machine based on `AuthService.user`. Apple Sign-In with SHA256 nonce. Debug builds include anonymous Firebase auth (`#if DEBUG` in `SignInView`).

### Firestore Structure

```
/users/{userId}           — AppUser (profile, defaultListId, settings)
/lists/{listId}           — ShoppingList (name, ownerId, memberIds[], inviteCode)
  /items/{itemId}         — Item (name, rawInput, category, status, source)
  /history/{historyId}    — HistoryEntry (action, purchaseCount)
```

Security rules enforce `memberIds`-based access. Subcollection rules use parent document lookups.

### Composite Indexes Required

- `lists`: memberIds (CONTAINS) + updatedAt (DESC)
- `items`: status (ASC) + category (ASC) + addedAt (DESC)
- `history`: action (ASC) + purchaseCount (DESC)

Missing indexes cause snapshot listeners to fail silently. Always deploy indexes after changes: `firebase deploy --only firestore:indexes`

## Key Patterns

- **Theme**: `SoftSageTheme.swift` — all colors, fonts, spacing, and per-category color schemes. Use `Theme.*` constants.
- **Completed items expire**: `completedItems` filters to items completed < 24 hours ago.
- **Image cleanup**: `parseImage` Cloud Function deletes uploaded image from Storage after parsing.
- **WidgetKit target**: Currently disabled in `project.yml` due to simulator "Invalid placeholder attributes" bug. Re-enable for device builds.
- **Siri**: `AddItemsIntent` (App Intents framework) uses static service helpers since it runs outside the view lifecycle.

## Cloud Functions

TypeScript source in `functions/src/`, compiled to `functions/lib/`. Runtime: Node.js 20. Gemini API key stored as Firebase secret (`GEMINI_API_KEY`). All callable functions validate `request.auth` before processing.

## Gotchas

- **Firestore listeners fail silently**: If a composite index is missing or a query is malformed, snapshot listeners return no data with no error. Add error logging to listener callbacks when debugging.
- **Simulator install with WidgetKit**: `xcrun simctl install` fails with "Invalid placeholder attributes" when the app embeds a WidgetKit extension. Workaround: strip `PlugIns/` from the .app bundle before installing, or disable the widget target in `project.yml`.
- **Firebase Anonymous Auth**: Must be enabled in Firebase Console > Authentication > Sign-in method before the debug sign-in button works.
- **UI tests require build-for-testing first**: Run `xcodebuild build-for-testing` before `test-without-building` when running from CLI.
- **XCUITest element matching**: Item names in list views are inside nested SwiftUI containers. Use `app.descendants(matching: .any)` with predicate matching, not `app.staticTexts["exact"]`.
