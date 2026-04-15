# Debug Sign-In with Firebase Anonymous Auth — Design Spec

## Overview

Add a debug-only sign-in option to bypass Apple Sign In on the simulator. Uses Firebase Anonymous Auth to create a real authenticated session so all app features work identically.

## Approach

A small "Sign in with test account" text link below the Apple Sign In button, guarded by `#if DEBUG`. Tapping it calls `Auth.auth().signInAnonymously()`, which creates a real Firebase user. The existing `AuthService` auth state listener picks up the session automatically.

## Changes

### Modify: `ShoppingList/Services/AuthService.swift`

Add one method to `AuthService`:

```swift
func signInAnonymously() async throws {
    let result = try await Auth.auth().signInAnonymously()
    try await createUserDocumentIfNeeded(result.user)
}
```

This creates an anonymous Firebase user with a real UID. The existing `createUserDocumentIfNeeded` handles user document creation with placeholder values ("Test User", empty email).

### Modify: `ShoppingList/Views/Auth/SignInView.swift`

After the Apple Sign In button and error message, add a `#if DEBUG` block containing a `Button` styled as muted secondary text:

- Label: "Sign in with test account"
- Style: `Theme.captionFont`, `Theme.textSecondary` color
- Action: calls `authService.signInAnonymously()`, sets `errorMessage` on failure

## What stays the same

- No Firebase console changes — anonymous auth is enabled by default.
- No build setting changes — `#if DEBUG` is a standard Swift compiler flag.
- No Firestore rule changes — anonymous users have a real `auth.uid`.
- The anonymous user document uses `displayName: "Test User"` from the existing `user.displayName ?? "User"` fallback in `createUserDocumentIfNeeded`.
