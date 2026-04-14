# Family Shopping List App — Design Spec

## Overview

A native iOS (Swift/SwiftUI) family shopping list app with AI-powered features. Multiple family members can collaborate on shared shopping lists in real-time, with smart input parsing, item categorization, purchase suggestions, and duplicate detection powered by Google Cloud AI.

**App Name:** TBD (to be decided during implementation)

## Architecture

### Approach: Firebase-Heavy

All backend services live in the Firebase/Google Cloud ecosystem:

- **SwiftUI** — native iOS app, local-first with Firestore offline persistence
- **Firebase Auth** — Apple Sign-In as the sole authentication provider
- **Cloud Firestore** — data storage, real-time sync, offline cache
- **Firebase Cloud Functions** — AI orchestration layer
- **Firebase Cloud Messaging** — push notifications
- **Firebase Dynamic Links** — invite link generation and handling
- **Firebase Storage** — temporary image uploads for photo parsing
- **Google Cloud AI (Gemini Flash)** — NLP parsing, categorization, suggestions, duplicate detection
- **Google Cloud Speech-to-Text** — fallback; primary speech-to-text is Apple Speech (on-device)
- **Apple Speech Framework** — on-device speech-to-text transcription

### Design Principles

- **Offline-first:** The app works fully without connectivity. Items are added locally and sync when back online. AI features queue and run when connectivity returns.
- **Real-time:** Firestore snapshot listeners provide instant cross-device updates.
- **AI is non-blocking:** If AI services are unavailable, items are saved as-is. Parsing and categorization run asynchronously and update items in place.
- **Cost-conscious:** All Gemini calls use Gemini Flash (fast, cheap). Batched and infrequent operations where possible.

## Data Model

All data lives in Cloud Firestore.

### Users (`users/{userId}`)

| Field | Type | Description |
|-------|------|-------------|
| `displayName` | string | From Apple Sign-In |
| `email` | string | From Apple Sign-In |
| `photoURL` | string | Profile photo URL |
| `createdAt` | timestamp | Account creation time |
| `lastActiveAt` | timestamp | Last app activity |
| `defaultListId` | string | List that opens on app launch |
| `settings` | map | Notification preferences, theme |

### Lists (`lists/{listId}`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | e.g. "Weekly Groceries", "Costco Run" |
| `ownerId` | string | User who created the list |
| `memberIds` | array[string] | All users with access (including owner) |
| `createdAt` | timestamp | List creation time |
| `updatedAt` | timestamp | Last modification |
| `inviteCode` | string | Unique code for invite links |

### Items (`lists/{listId}/items/{itemId}`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name (e.g. "Whole milk") |
| `rawInput` | string | Original text/voice input |
| `quantity` | string | Optional (e.g. "2 lbs", "1 dozen") |
| `category` | string | AI-assigned grouping (e.g. "Dairy", "Produce") |
| `flagged` | bool | Star/flag importance toggle |
| `status` | string | `active` or `completed` |
| `completedAt` | timestamp | When checked off |
| `completedBy` | string | userId who checked it off |
| `addedBy` | string | userId who added it |
| `addedAt` | timestamp | When added |
| `source` | string | `text`, `voice`, or `photo` |

### History (`lists/{listId}/history/{historyId}`)

| Field | Type | Description |
|-------|------|-------------|
| `itemName` | string | Item name at time of action |
| `category` | string | Category at time of action |
| `action` | string | `added`, `completed`, `removed`, `re-added` |
| `userId` | string | Who performed the action |
| `timestamp` | timestamp | When it happened |
| `purchaseCount` | int | Incremented each time this item is bought |

## AI Pipeline

Five Cloud Functions powered by Gemini Flash:

### 1. Parse Input

- **Trigger:** Firestore `onCreate` on `items` subcollection
- **Input:** `rawInput` text from the new item document
- **Process:** Calls Gemini to extract item name(s), quantity, and suggested category
- **Multi-item handling:** If multiple items detected ("milk, eggs, and bread"), creates additional item documents and deletes the original
- **Output:** Updates item document(s) with parsed `name`, `quantity`, and `category`
- **Failure mode:** Item retains `rawInput` as `name`, categorization retries later

### 2. Parse Image

- **Trigger:** HTTPS-callable function
- **Input:** Image URL from Firebase Storage
- **Process:** Sends image to Gemini Vision to extract items from recipes, shelf photos, or handwritten notes
- **Output:** Returns array of extracted items with names and optional quantities
- **Failure mode:** Returns error; app shows "Couldn't read this image" with manual fallback

### 3. Categorize Items

- **Trigger:** Runs on items that weren't categorized during initial parsing
- **Categories:** Produce, Dairy, Meat, Bakery, Frozen, Beverages, Snacks, Pantry, Household, Personal Care, Other
- **Output:** Updates item's `category` field
- **User override:** Users can manually change category; overrides are respected and not re-categorized

### 4. Suggest Frequent Items

- **Trigger:** HTTPS-callable function (on-demand from UI)
- **Process:** Queries history for the list, ranks by `purchaseCount` and recency, uses Gemini to filter out seasonal/one-off items
- **Output:** Returns ranked list of suggested items not currently on the active list
- **Smart filtering:** Excludes items already on the list, considers purchase frequency patterns

### 5. Review Duplicates

- **Trigger:** On-demand from list menu or pull-to-refresh
- **Process:** Reads all active items, sends to Gemini to identify duplicates and near-duplicates
- **Output:** Returns groups of similar items (e.g. ["Milk", "Whole milk", "2% milk"])
- **User action:** Merge (pick one name), keep both, or dismiss

## App Screens & Navigation

### Tab Bar (3 tabs)

#### 1. Lists Tab (Home)

- All lists the user belongs to
- Each list card: name, item count, member avatars, last updated
- Tap to open list detail
- "+" button to create new list
- Swipe actions: leave list, delete (owner only)

#### 2. List Detail Screen (Main Working Screen)

- Active items grouped by AI-assigned category
- "Completed" section collapsed at bottom (auto-clears after 24 hours)
- Each item row: flag star, item name, quantity, who added it
- Tap to check off, long-press for edit/delete
- **Input bar at bottom:**
  - Text field (supports natural language)
  - Mic button (voice input via Apple Speech)
  - Camera button (photo input)
- Pull-to-refresh triggers duplicate review
- Top-right menu: list settings, invite members, view history, suggestions, run duplicate check

#### 3. Activity Tab

- Unified history feed across all lists
- Shows: who added/completed/removed what, and when
- Filter by list, by member, or by date range
- Tap a past item to re-add it to any list

### Supporting Screens

- **List Settings** — rename list, manage members, notification preferences per list, clear completed, delete list
- **Invite Flow** — generates shareable Dynamic Link, shows pending invites
- **Suggestions** — AI-generated "frequently bought" items with one-tap re-add
- **Profile/Settings** — account info, notification preferences, default list selection
- **Photo Confirmation** — after image parsing, shows extracted items for user to confirm before adding

## Key User Flows

### Adding Items via Text

1. User taps text field, types "2 lbs chicken and some rice"
2. Item written to Firestore with `rawInput` and `source: text`
3. Cloud Function triggers, calls Gemini to parse
4. Two items created: "Chicken (2 lbs)" in Meat, "Rice" in Pantry
5. List updates in real-time for all members

### Adding Items via Voice

1. User taps mic button
2. Apple Speech framework transcribes on-device
3. Transcription sent as `rawInput` with `source: voice`
4. Same Cloud Function parsing flow as text

### Adding Items via Photo

1. User taps camera, takes photo of recipe page
2. Image uploaded to Firebase Storage
3. App calls Parse Image Cloud Function
4. Gemini Vision extracts items
5. User sees confirmation screen: "I found these items — add all?"
6. Confirmed items written to list

### Shopping Trip

1. Open list — items grouped by category (aisle-friendly)
2. Tap items to check off — they slide to "Completed" section
3. History records each completion with timestamp and who did it
4. After 24 hours, completed items auto-clear (still in history)

### Getting Suggestions

1. User taps "Suggestions" from list menu
2. Cloud Function queries history, ranks by frequency and recency
3. Returns frequently bought items not currently on list
4. User taps to add any suggestion with one tap

### Duplicate Review

1. Triggered on-demand or via pull-to-refresh
2. Cloud Function reads active items, sends to Gemini
3. Returns groups of similar items
4. User can merge, keep both, or dismiss

### Invite Flow

1. Owner taps "Invite" in list settings
2. Firebase Dynamic Link generated with list's invite code
3. Owner shares via iMessage, WhatsApp, etc.
4. Recipient taps link — app opens (or App Store if not installed)
5. After sign-in, list appears in their Lists tab

## Authentication & Sharing

- **Auth:** Apple Sign-In only, via Firebase Auth
- **Sharing model:** Equal access — all members can add, edit, check off, and flag items
- **Owner privileges:** Only the list creator can delete the list or remove members
- **Invite mechanism:** Firebase Dynamic Links with embedded invite code
- **Duplicate invite handling:** No-op if already a member
- **Member removal:** Immediate access revocation, list disappears from removed member's view

## Notifications

**Firebase Cloud Messaging push notifications:**

- "Tom added 5 items to Weekly Groceries"
- "Sarah checked off all items in Costco Run"
- "New suggestion: You usually buy eggs around this time"
- Batched: multiple rapid changes grouped into a single notification
- Per-list notification preferences: all activity, only additions, off

## iOS Widgets

- **Small widget:** Item count and top flagged items for default list
- **Medium widget:** Next few unchecked items grouped by category
- **Tap action:** Opens app directly to the relevant list

## Visual Design

**Style: Soft Sage — Warm & Friendly**

- Fresh greens and natural tones with a calm, organic feel
- Soft pastel category headers (green for Produce, blue for Dairy, etc.)
- Warm off-white background (`#FAFDF9`)
- Primary accent: sage green (`#2E7D32`)
- Secondary accent: soft green (`#81C784`)
- Rounded corners, gentle shadows, generous spacing
- Star/flag toggle in warm amber (`#FFB300`)
- Typography: SF Pro (system default), clean hierarchy

## Edge Cases & Error Handling

**AI Failures:**
- Items saved as-is with raw text as name. Categorization retries when service recovers.
- Image parsing failure: clear error message with manual fallback.

**Offline:**
- Full read/write access to cached lists. Subtle "Offline" banner.
- Voice input works offline (Apple Speech). AI parsing queues until online.
- Photo capture queues; parsing runs when connected.

**Invite Edge Cases:**
- No app installed: Dynamic Link redirects to App Store. Post-install, list auto-joins.
- Duplicate invite tap: no-op with "Already a member" message.
- Member removal: immediate revocation.

**Data Limits:**
- UI optimized for up to ~200 active items per list.
- History retention: unlimited, append-only.
- Completed items auto-clear from active view after 24 hours.

**Concurrent Edits:**
- Same item checked off by two people: first write wins, second sees it completed.
- Same item edited simultaneously: last write wins, both versions in history.
