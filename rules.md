# AaravPOS Agent Rules

These rules must be strictly followed by any AI agent or developer touching the AaravPOS codebase.

## 1. Extension Methods for Spacing
**Rule:** MUST use `SpaceExtension` from `lib/core/utils/extensions/space_extension.dart` instead of `SizedBox` directly.
**Why:** Consistent syntax and readability across the application.

❌ **Incorrect:**
```dart
const SizedBox(width: 8)
SizedBox(height: 16)
SizedBox(height: AppSpacing.md)
```

✅ **Correct:**
```dart
8.hs
16.vs
AppSpacing.md.vs
```

**Note:** Be mindful of `const` lists when replacing spacing. Extensions generate non-const widgets, so lists containing `.vs` or `.hs` cannot be declared as `const []`. You must distribute `const` to the other static widgets within the list instead.

## 2. Shared Widgets
If a widget like `ServiceCard`, `StaffCard`, `CustomerDropdown`, `SignaturePad`, or `SlotChip` is defined, it must reside in `lib/shared/widgets/`. Do not create identical generic UI elements inside feature-specific folders unless it is inextricably bound to a single niche use case.
