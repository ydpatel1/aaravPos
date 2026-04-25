# AaravPOS Kiosk Booking App — Engineering Guidelines + Product Requirements

> This document combines:
> - Project architecture
> - Coding rules
> - UI standards
> - API flow
> - Navigation flow
> - Feature requirements
> - AI agent prompt
> - Platform-specific UI rules
>
> Base task source: AaravPOS Practical Task document.

---

# 1. Tech Stack

### Required
- Flutter
- flutter_bloc
- Dio
- GoRouter
- GetIt
- Flutter Secure Storage
- Shimmer
- Signature package
- Intl

### Optional
- freezed
- json_serializable
- cached_network_image

---

# 2. Project Structure

```bash
lib/
 ├── core/
 │   ├── constants/
 │   ├── theme/
 │   ├── network/
 │   ├── router/
 │   ├── storage/
 │   ├── utils/
 │   │   ├── extensions/
 │   │   ├── validators/
 │   │   ├── helpers/
 │
 ├── shared/
 │   ├── widgets/
 │   ├── models/
 │
 ├── features/
 │   ├── auth/
 │   ├── booking/
 │
 ├── main.dart
```

---

# 3. BLoC Structure

### AuthBloc
- login
- logout
- remember me

### SessionCubit
Stores:
- checkin mode
- selected services
- selected staff
- selected date
- selected slot
- selected customer

### ServiceBloc
- fetch services
- select services

### StaffBloc
- fetch staff

### SlotBloc
- fetch slots
- auto nearest slot logic

### CustomerBloc
- customer search
- debounce

### ConsentBloc
- consent check
- sign consent

### BookingBloc
- final booking

---

# 4. Coding Rules

## File Size Rule
- Screen should ideally stay below **400 lines**
- If screen becomes too large:
  - move sections into widgets
  - move form fields into widgets
  - move reusable logic into helpers

### Exception
Large forms may go to 500–600 lines if logically grouped.

---

# 5. No Duplicate Code Rule

❌ No copy-paste widgets
❌ No repeated validation logic
❌ No repeated API calls

Always extract reusable code.

---

# 6. Extensions Usage

## Spacing Extension

```dart
extension SpaceExtension on num {
  SizedBox get hs => SizedBox(width: toDouble());
  SizedBox get vs => SizedBox(height: toDouble());
}
```

Usage:

```dart
16.vs
20.hs
```

---

## Context Extension

```dart
context.width
context.height
```

---

## Date Extension

Reusable formatting helpers.

---

# 7. Common Widgets

```bash
shared/widgets/
```

### Required Common Widgets
- AppButton
- AppTextField
- AppLoader
- CommonAppBar
- EmptyStateWidget
- ErrorStateWidget
- NetworkImageWidget
- ConfirmationDialog

### Booking Widgets
- ServiceCard
- StaffCard
- SlotChip
- CustomerDropdown
- SignaturePad

---

# 8. UI Theme

## Primary Color
`#E53935`

## Secondary
`#FCE4EC`

## Background
`#FFFFFF`

## Disabled
`#BDBDBD`

## Border
`#E0E0E0`

## Text
`#212121`

---

# 9. Spacing Rules

- 4
- 8
- 12
- 16
- 20
- 24
- 32

Do not use random spacing values.

---

# 10. iOS Glass Effect Rule

### iOS only
Use glassmorphism effect on:
- top headers
- cards
- dialogs

Use:
- BackdropFilter
- blur effect
- semi-transparent white

Example:

```dart
if (Platform.isIOS) {
  // show glass effect
}
```

---

# 11. Android UI Rule

Use normal material design.

No glass effect.

---

# 12. Screen Flow

## Login
→ Home

## Home
Appointment → Services
Check-In → Services

## Services
→ Staff

## Staff
→ Date OR Skip

## Date
→ Slots

## Check-in
Skip Date
Skip Slot

## Review
→ Consent

## Consent
→ Booking API

## Success
→ Details

## Details
→ Home

---

# 13. Screen Requirements

---

## Login Screen
API:
POST auth/login

UI:
- email field
- password field
- remember me checkbox
- login button

Navigation:
Success → Home

---

## Home Screen
UI:
- appointment card
- check-in card
- logout FAB

---

## Service Screen
API:
GET services

UI:
- 3 column grid
- category expandable section
- shimmer loading

---

## Staff Screen
API:
GET staff

UI:
- pastel cards
- selected red border

---

## Date Screen
UI:
- calendar
- disable past dates

---

## Slot Screen
API:
GET slots

UI:
- morning
- afternoon
- evening

---

## Review Screen
API:
GET customer list

UI:
- phone autocomplete
- customer form
- summary panel

Tablet:
2 column layout

---

## Consent Screen
API:
GET consent check
POST consent sign

UI:
- consent text
- signature pad
- checkbox

---

## Success Screen
UI:
- lottie animation

---

## Details Screen
UI:
- booking summary
- services
- subtotal

---

# 14. API Flow

Login
→ outlet status
→ services
→ staff
→ slots
→ customer
→ consent
→ booking

---

# 15. Error Handling

Must handle:
- network failure
- token expiry
- no slots
- no staff
- no services
- customer not found
- booking failure

---

# 16. Loading States

Use shimmer for:
- services
- slots

Use loader for:
- login
- booking
- consent submit

---

# 17. Responsive Rules

### Mobile
single column

### Tablet
multi column

Review screen:
2 columns

---

# 18. Performance Rules

- paginate if needed
- avoid unnecessary rebuilds
- use const widgets
- cache images

---

# 19. Clean Architecture Rules

UI layer should never directly call APIs.

Flow:
UI → Bloc → Repository → API

---

# 20. Testing Checklist

- login
- checkin flow
- appointment flow
- consent flow
- no slots
- no customer
- booking success

---

# 21. UI Screenshots

Attach actual design screenshots here:

- login.png
- home.png
- service.png
- staff.png
- slot.png
- review.png
- consent.png
- success.png
- details.png

---

# 22. AI Agent Prompt

Use this prompt with any AI coding agent:

---

Build a production-grade Flutter application using flutter_bloc architecture.

Rules:
- Follow feature-first architecture
- Use Dio for API
- Use GoRouter
- Use GetIt DI
- Use common widgets
- No duplicate code
- Use spacing extensions (.vs/.hs)
- Keep screens under 400 lines when possible
- Extract reusable widgets
- Follow clean architecture
- Implement both appointment and check-in flow
- Handle consent logic
- Add shimmer loading
- Build tablet responsive UI
- Apply glassmorphism only on iOS
- Android should use material UI
- Add proper error handling
- Add scalable architecture

Create production-ready code only.

---

# Final Goal

Build maintainable, scalable, readable production-level kiosk booking application.

