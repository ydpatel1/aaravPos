# Review & Confirm Screen — Full Technical Documentation

**File:** `lib/ui/pickering/view/review_confirm_screen.dart`  
**Controller:** `lib/ui/pickering/controller/review_confirm_controller.dart`  
**Route:** `/BookingReviewScreen`

---

## 1. Overview

The **Review & Confirm** screen is the final step before an appointment or check-in is created. It shows the user a summary of their booking (outlet, services, date, time, total price) and collects their contact information. It also handles **consent form signing** for services that require it.

---

## 2. Screen Layout

### Responsive Design
- **Mobile** (`width < 600px`): Booking summary card on top, contact form below, bottom bar at the bottom.
- **Tablet** (`width >= 600px` / `>= 1024px`): Two-column layout — booking summary on the left (flex 5), contact form on the right (flex 5), constrained to max width 1200px.

### Sections
| Section | Description |
|---|---|
| AppBar | "Review & Confirm" title, back button |
| Booking Summary Card | Outlet name, services list (name, duration, price, consent badge), date, time |
| Contact Form Card | Mobile number (with country code picker + customer dropdown), First Name*, Last Name, Email |
| Bottom Bar | Total price, service count, Cancel button, Sign Consent / Continue button |

---

## 3. Contact Form Fields

| Field | Required | Validation |
|---|---|---|
| Mobile Number | Yes (if email empty) | Must be exactly 10 digits |
| Country Code | — | Picker, default `+1` (US) |
| First Name | Yes | Cannot be empty |
| Last Name | No | No validation |
| Email | No | Must contain `@` if provided |

> **Note:** Phone OR Email is required — at least one must be filled.

---

## 4. Phone Number Search (Customer Lookup)

### Trigger
When the user types **8 or 9 digits** in the phone field, `_handlePhoneChange()` fires and calls `controller.searchCustomer(countryCode, phone)`.

When the user clears below 8 digits, `controller.clearCustomerSelection()` is called — resets all customer and consent state.

### API Call — Customer Search
```
GET {baseUrl}customer/list/{tenantId}?page=1&limit=20&search={countryCode+phone}
Authorization: Bearer {token}
```

### Response Handling

| Scenario | Action |
|---|---|
| `success == true` AND results found | Populate `customerList`, show dropdown, `isCustomerNotFound = false` |
| No results / empty list | Clear dropdown, `isCustomerNotFound = true`, call `_evaluateConsentForNewCustomer()` |
| Error / exception | Clear dropdown, `isCustomerNotFound = false` |

### Customer Dropdown
- Shown below the phone field when `showCustomerDropdown == true` and `customerList` is not empty.
- Each item shows: **Full Name** + Phone + Email.
- Tapping a customer calls `_handleCustomerSelection(customer)`:
  - Fills First Name, Last Name, Email fields automatically.
  - Calls `controller.selectCustomer(customer)` → stores `customerId` and triggers consent check.

---

## 5. Consent System

### 5.1 What Triggers Consent?

A service requires consent when **all** of the following are true:
- `service.requiresConsent == true`
- `service.consentFormId != null` (non-empty)
- `service.consentRule != null`

### 5.2 Consent Types by Signing Frequency

#### A. `EVERY_VISIT` + `MULTIPLE` enforcement + `KIOSK` channel rule
- **No API call needed** — always requires signing on every visit.
- Marked directly: `needsSignature = true` (triggers "Sign Consent" button).
- Applies to both existing and new customers.

#### B. `ONCE_PER_CUSTOMER`
- **API call required** to check if the customer has signed before.
- Only applies when a customer is selected (has a `customerId`).

#### C. New / Unregistered Customer (`isCustomerNotFound == true`)
- No API call possible (no `customerId`).
- Evaluated locally via `_evaluateConsentForNewCustomer()`:
  - `EVERY_VISIT + MULTIPLE + KIOSK` → `needsSignature = true`, `isNewCustomerEntry = true`
  - `ONCE_PER_CUSTOMER + KIOSK` → `needsSignature = true`, `isNewCustomerEntry = true`

### 5.3 Consent Check API (ONCE_PER_CUSTOMER only)

```
GET {baseUrl}concent/check/{customerId}/{consentFormId}?serviceId={serviceId}
Authorization: Bearer {token}
```

**Response shape:**
```json
{
  "success": true,
  "message": "Check completed",
  "data": {
    "needsSignature": false,
    "reason": "No consent rule applies to this form",
    "hasPreviousSignature": false,
    "signatureExists": false,
    "consentInstanceExists": false
  }
}
```

| `needsSignature` value | Meaning |
|---|---|
| `false` | Customer has NOT signed before → **must sign** (mandatory) |
| `true` | Customer already signed → optional re-sign |

> On API error / non-200 response: safe fallback → `needsSignature = false` (treat as must-sign).

### 5.4 Reactive Flags (computed by `_recompute()`)

| Flag | Condition | Effect |
|---|---|---|
| `hasUnsignedConsent` | Any `needsSignature == false` result not yet signed in session | Internal tracking |
| `hasOptionalConsent` | Any `needsSignature == true` result not yet signed in session | Shows "Sign Consent" button |
| `showSignConsentButton` | `hasOptionalConsent == true` OR new customer has any unsigned consent | Replaces "Continue" with "Sign Consent" button |
| `hasPendingMandatoryConsent` | New customer has unsigned `ONCE_PER_CUSTOMER` consent | **Disables** "Continue" button |

---

## 6. Bottom Bar Buttons

### Cancel Button
- Always visible.
- Navigates to `InitialScreen` (clears entire navigation stack via `Get.offAllNamed`).

### Sign Consent Button
- Shown when `showSignConsentButton == true`.
- Priority: opens dialog for **mandatory unsigned** services first (`servicesNeedingConsent`), then optional (`servicesWithOptionalConsent`).
- Opens `_ConsentDialog` for the first service in the list.

### Continue Button
- Shown when `showSignConsentButton == false`.
- **Disabled** (greyed out) when `isCreatingAppointment == true` OR `hasPendingMandatoryConsent == true`.
- On tap → calls `_handleConfirm()`.

---

## 7. Confirm Flow (`_handleConfirm`)

1. Sets `_autoValidate = true` → triggers form validation on all fields.
2. If form is **invalid** → stops, shows inline errors.
3. If form is **valid** → dismisses keyboard, calls `controller.createBooking(...)`.

---

## 8. Create Booking API

### Mode Detection
```dart
final isCheckIn = userController.isUserChecking == true;
```

---

### 8.1 Check-In Mode

**URL:** `POST {baseUrl}appointment/checkin`

**Payload:**
```json
{
  "tenantId": "string",
  "outletId": "string",
  "staffId": "string",
  "serviceIds": ["serviceId1", "serviceId2"],
  "slotIds": ["slotId1"],
  "date": "yyyy-MM-dd",
  "startTime": "HH:mm",
  "customer": {
    "first_name": "string",
    "last_name": "string",
    "email": "string | null",
    "phone": "+countryCode+phoneNumber"
  }
}
```

---

### 8.2 Appointment Mode

**URL:** `POST {baseUrl}appointment`

**Payload:**
```json
{
  "tenantId": "string",
  "outletId": "string",
  "staffId": "string",
  "serviceIds": ["serviceId1", "serviceId2"],
  "slotIds": ["slotId1"],
  "date": "yyyy-MM-dd",
  "isWalkIn": false,
  "startTime": "HH:mm",
  "customer": {
    "first_name": "string",
    "last_name": "string",
    "email": "string | null",
    "phone": "+countryCode+phoneNumber",
    "gender": "",
    "date_of_birth": ""
  }
}
```

> **Conditional field:** If any selected service has `consentRule.enforcementMode == 'FIXED'`, the field `"requiresConsent": true` is added to the payload.

---

### 8.3 API Response Handling

**Success (200 / 201):**
- Parses `appointmentId` from `data.id` or `data.appointmentId`.
- Parses `customerId` from `data.customerId` or falls back to the selected `customerId`.
- Builds `appointmentDetails` map for the confirmation screen.
- If `signedConsents` is not empty → calls `_submitConsentSignatures(...)`.
- If consent submission succeeds → navigates to `AppointmentConfirmationScreen`.

**Failure (non-200/201):**
- Shows error snackbar with message from `response.body['message']`.

---

## 9. Consent Signature Submission

### API Call

```
POST {baseUrl}concent/customer-sign
Authorization: Bearer {token}
Content-Type: application/json
```

### Payload by Signing Method

#### TYPED_NAME
```json
{
  "tenantId": "string",
  "appointmentId": "string",
  "customerId": "string",
  "serviceIds": ["serviceId"],
  "outletId": "string",
  "concentFormId": "string",
  "signatureType": "TYPED_NAME",
  "channel": "POS",
  "staffId": "string",
  "typedName": "Customer Typed Name"
}
```

#### CHECKBOX_ONLY
```json
{
  "tenantId": "string",
  "appointmentId": "string",
  "customerId": "string",
  "serviceIds": ["serviceId"],
  "outletId": "string",
  "concentFormId": "string",
  "signatureType": "CHECKBOX_ONLY",
  "channel": "POS",
  "staffId": "string",
  "isChecked": true
}
```

#### DRAW_SIGNATURE
```json
{
  "tenantId": "string",
  "appointmentId": "string",
  "customerId": "string",
  "serviceIds": ["serviceId"],
  "outletId": "string",
  "concentFormId": "string",
  "signatureType": "SIGNATURE_IMAGE",
  "channel": "POS",
  "staffId": "string",
  "imageUrl": "data:image/png;base64,<base64EncodedPNG>"
}
```

### Consent Submission Failure Handling
1. Removes the failed service from `signedConsents`.
2. Sets `consentSignFailed = true` and `failedConsentServiceId = serviceId`.
3. Shows error snackbar ("Consent Error").
4. Stays on the Review & Confirm screen (does NOT navigate away).
5. After 600ms delay, `_openConsentDialogForResubmit(service)` is called automatically.
6. User re-signs → `markConsentSigned()` + `resubmitConsentAfterFailure()` called.
7. `resubmitConsentAfterFailure()` calls `_submitConsentSignatures()` again using stored `_pendingAppointmentId`, `_pendingCustomerId`, `_pendingToken`.
8. If successful → navigates to `AppointmentConfirmationScreen`.

---

## 10. Consent Dialog (`_ConsentDialog`)

### When It Opens
- User taps **"Sign Consent"** button.
- Automatically reopened after a consent sign API failure.

### Dialog Properties
- `barrierDismissible: false` — user cannot dismiss by tapping outside.
- Max size: `900 x 700` px.
- Background: `Color(0xFFF5F5F5)`.

### Dialog Content
1. **Title** — from `service.consentTemplate.heading` (fallback: "Consent Form Title").
2. **Scrollable consent text** — from `service.consentTemplate.consent` (fallback: default consent paragraph).
3. **Bottom input section** — varies by signing method (see below).
4. **Action buttons** — Confirm + Cancel.

### Signing Method Detection
```dart
// Finds the KIOSK channel rule index in the service's consentRule.channelRules
final index = service.consentRule?.channelRules?.indexWhere((r) => r.channel == 'KIOSK');
final signingMethod = service.consentRule?.channelRules![index!].method;
```

### Signing Method UI

#### `TYPED_NAME`
- Label: "Type Your Name"
- Text field — user types their name.
- Confirm enabled when field is not empty.

#### `CHECKBOX_ONLY`
- Checkbox + label: "I accept the terms and conditions"
- Confirm enabled when checkbox is checked.

#### `DRAW_SIGNATURE`
- Label: "Sign Here"
- Freehand signature pad (120px tall, white background).
  - `onPanStart` → starts new stroke.
  - `onPanUpdate` → adds points to current stroke, sets `_hasSigned = true`.
  - `onPanEnd` → commits stroke to `_strokes` list.
- "Clear" button — resets all strokes.
- "Email me" checkbox (UI only, no backend action currently).
- Confirm enabled when at least one stroke has been drawn.

### Confirm Button Logic
1. Validates `_canConfirm` — if false, shows snackbar "Please complete the consent form before confirming."
2. Builds `SignedConsentData(method, payload, signedAt)`:
   - `TYPED_NAME` → payload = typed text
   - `CHECKBOX_ONLY` → payload = `"true"`
   - `DRAW_SIGNATURE` → renders strokes to 600×200 PNG, encodes as base64 data URI
3. Calls `onConfirm(SignedConsentData)` callback.
4. Closes dialog (`Navigator.of(context).pop()`).

### Cancel Button
- Closes dialog without saving anything.

---

## 11. Navigation After Success

```
AppointmentConfirmationScreen (route: /AppointmentConfirmationScreen)
```

**Arguments passed:**
```dart
{
  'apiResponse': <raw API response data>,
  'date': 'yyyy-MM-dd',
  'startTime': 'HH:mm',
  'services': [
    { 'name': 'string', 'duration': 'X min', 'price': double }
  ],
  'staffName': 'string',
  'customerName': 'FirstName LastName',
  'isCheckIn': bool,
}
```

Navigation uses `Get.offNamed(...)` — the Review & Confirm screen is removed from the stack.

---

## 12. Complete Flow Diagram

```
User arrives at Review & Confirm Screen
        │
        ├─ Booking summary displayed (outlet, services, date, time, total)
        │
        ├─ User enters phone number
        │       │
        │       ├─ 8-9 digits typed → Customer Search API called
        │       │       │
        │       │       ├─ Customer(s) found → Dropdown shown
        │       │       │       └─ User selects customer
        │       │       │               └─ Consent Check API called (ONCE_PER_CUSTOMER services)
        │       │       │                       ├─ needsSignature=false → must sign (mandatory)
        │       │       │                       └─ needsSignature=true  → optional re-sign
        │       │       │
        │       │       └─ No customer found → isCustomerNotFound=true
        │       │               └─ _evaluateConsentForNewCustomer()
        │       │                       ├─ EVERY_VISIT+MULTIPLE+KIOSK → needsSignature=true
        │       │                       └─ ONCE_PER_CUSTOMER+KIOSK    → needsSignature=true (mandatory)
        │       │
        │       └─ < 8 digits → clearCustomerSelection()
        │
        ├─ User fills First Name, Last Name, Email
        │
        ├─ Bottom Bar shows:
        │       ├─ showSignConsentButton=true  → "Sign Consent" button shown
        │       │       └─ User taps → Consent Dialog opens
        │       │               ├─ TYPED_NAME   → type name → Confirm
        │       │               ├─ CHECKBOX_ONLY → check box → Confirm
        │       │               └─ DRAW_SIGNATURE → draw → Confirm
        │       │                       └─ markConsentSigned() → _recompute()
        │       │                               └─ If all consents signed → "Continue" shown
        │       │
        │       └─ showSignConsentButton=false → "Continue" button shown
        │               ├─ hasPendingMandatoryConsent=true → button DISABLED (grey)
        │               └─ hasPendingMandatoryConsent=false → button ENABLED
        │
        └─ User taps "Continue"
                │
                ├─ Form validation (phone/email, first name, email format)
                │       └─ Invalid → show inline errors, stop
                │
                └─ Valid → createBooking() called
                        │
                        ├─ isCheckIn=true  → POST /appointment/checkin
                        └─ isCheckIn=false → POST /appointment
                                │
                                ├─ Success (200/201)
                                │       ├─ signedConsents not empty?
                                │       │       └─ POST /concent/customer-sign (per service)
                                │       │               ├─ All OK → navigate to AppointmentConfirmationScreen
                                │       │               └─ Any fail → stay on screen, reopen consent dialog
                                │       │                       └─ User re-signs → resubmitConsentAfterFailure()
                                │       │                               └─ POST /concent/customer-sign again
                                │       │                                       └─ OK → navigate to AppointmentConfirmationScreen
                                │       └─ No consents → navigate to AppointmentConfirmationScreen
                                │
                                └─ Failure → show error snackbar
```

---

## 13. Key Models

### `BookingData`
Passed as `Get.arguments` to this screen. Contains all booking context from previous screens.

| Field | Type | Description |
|---|---|---|
| `tenantId` | `String?` | Tenant identifier |
| `outletId` | `String?` | Outlet identifier |
| `outletName` | `String?` | Display name of outlet |
| `services` | `List<ServiceDetails>?` | Selected services |
| `selectedDate` | `DateTime?` | Appointment date |
| `staffId` | `String?` | Selected staff ID |
| `staffName` | `String?` | Selected staff name |
| `slotIds` | `List<String>?` | Selected time slot IDs |
| `startTime` | `String?` | ISO datetime string for start |
| `totalPrice` | `double?` | Computed sum of all service prices |
| `serviceCount` | `int` | Number of selected services |

### `ServiceDetails`
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Service ID |
| `name` | `String` | Service name |
| `price` | `double` | Service price |
| `duration` | `int` | Duration in minutes |
| `requiresConsent` | `bool` | Whether consent is needed |
| `consentTemplate` | `ConsentTemplate?` | Heading + consent text |
| `consentRule` | `ConsentRule?` | Enforcement mode, channel rules, signing frequency |
| `signingFrequency` | `String?` | `ONCE_PER_CUSTOMER` or `EVERY_VISIT` |
| `consentFormId` | `String?` | ID used in consent check API |

### `ConsentCheckResult`
| Field | Type | Description |
|---|---|---|
| `serviceId` | `String` | Service this result belongs to |
| `needsSignature` | `bool` | `false` = must sign, `true` = already signed (optional) |
| `hasPreviousSignature` | `bool` | Whether a prior signature exists |
| `signatureExists` | `bool` | Whether signature record exists |
| `isNewCustomerEntry` | `bool` | Synthetic entry for unregistered customer |

### `SignedConsentData`
| Field | Type | Description |
|---|---|---|
| `method` | `String` | `TYPED_NAME`, `CHECKBOX_ONLY`, or `DRAW_SIGNATURE` |
| `payload` | `String` | Typed name / "true" / base64 PNG data URI |
| `signedAt` | `DateTime` | Timestamp of signing |

---

## 14. API Summary Table

| # | Method | Endpoint | When Called | Auth |
|---|---|---|---|---|
| 1 | GET | `customer/list/{tenantId}?page=1&limit=20&search={phone}` | Phone 8-9 digits typed | Bearer token |
| 2 | GET | `concent/check/{customerId}/{consentFormId}?serviceId={serviceId}` | Customer selected, ONCE_PER_CUSTOMER service | Bearer token |
| 3 | POST | `appointment/checkin` | Confirm tapped, `isUserChecking == true` | Bearer token |
| 4 | POST | `appointment` | Confirm tapped, `isUserChecking == false` | Bearer token |
| 5 | POST | `concent/customer-sign` | After appointment created, if consents were signed | Bearer token |
