# Slot Selection Logic — Full Functionality Reference

> Covers both **Appointment** and **Check-In** flows.  
> Last reviewed: May 2026

---

## 1. Core Concept: How Slots Work

The backend exposes time in **15-minute raw slots**.  
Each raw slot has:

| Field | Type | Example |
|---|---|---|
| `id` | String (UUID) | `"9d7499ad-95a5-..."` |
| `start_time` | `"HH:mm"` | `"10:00"` |
| `end_time` | `"HH:mm"` | `"10:15"` |
| `isBooked` | bool | `false` |
| `date` | String? | `"2026-05-01"` |

**Key rule:** If a service takes 20 minutes, the system needs `ceil(20 / 15) = 2` consecutive unbooked slots. If it takes 45 minutes, it needs `ceil(45 / 15) = 3` slots. This is the foundation of all slot selection logic.

```
Formula:  slotsNeeded = (serviceDuration / 15).ceil()
```

---

## 2. API Endpoint

```
GET /staff/slots/{staffId}?date=yyyy-MM-dd
Authorization: Bearer {token}
```

**Response shape:**
```json
{
  "success": true,
  "data": {
    "groups": {
      "morning":   [ { "id": "...", "start_time": "08:00", "end_time": "08:15", "isBooked": false } ],
      "afternoon": [ ... ],
      "evening":   [ ... ]
    }
  }
}
```

Slots are pre-grouped by the API into morning / afternoon / evening buckets.

---

## 3. Data Models

### `RawTimeSlot` (individual 15-min slot from API)
```dart
// lib/ui/pickering/controller/time_slot_controller.dart
class RawTimeSlot {
  final String  id;
  final String  startTime;  // "HH:mm"
  final String  endTime;    // "HH:mm"
  final bool    isBooked;
  final String? date;
}
```

### `TimeSlot` (grouped slot — used in check-in auto-selection)
```dart
class TimeSlot {
  final String       startTime;  // ISO8601 DateTime string
  final String       endTime;    // ISO8601 DateTime string
  final List<String> slotIds;    // all 15-min slot IDs in this group
  final bool         isBooked;
  final int          startHour;
}
```

### `BookingData` (passed between screens)
```dart
// lib/model/book_appointment_model.dart
class BookingData {
  String?       staffId;
  String?       staffName;
  DateTime?     selectedDate;
  String?       startTime;       // ISO8601 — set after slot selection
  String?       endTime;         // ISO8601 — set after slot selection
  List<String>? slotIds;         // all slot IDs to book
  List<ServiceDetails>? services;
  // ... tenant, outlet, customer fields
}
```

`BookingData` also exposes two computed getters (defined in `ServiceSelectionController.getBookingData()`):
- `totalDuration` — sum of all selected service durations in minutes
- `totalPrice` — sum of all selected service prices
- `serviceCount` — number of selected services

---

## 4. Appointment Flow — Step by Step

```
InitialScreen
    │  (tap "Appointment")
    │  userController.isUserChecking = false
    ▼
ServiceSelectionScreen          ← user picks services
    │  BookingData built with services list + totalDuration
    ▼
BarberScreen                    ← user picks staff
    │  BookingData.copyWith(staffId, staffName)
    │  isUserChecking == false → go to calendar
    ▼
CalendarSelectionScreen         ← user picks date
    │  BookingData.copyWith(selectedDate)
    ▼
TimeSlotScreen                  ← user manually picks a slot
    │  BookingData.copyWith(startTime, endTime, slotIds)
    ▼
BookingReviewScreen             ← customer details + consent
    ▼
POST /appointment
    ▼
AppointmentConfirmationScreen
```

### 4.1 Loading Slots (`TimeSlotController.loadRawTimeSlots`)

Called in `TimeSlotScreen.initState()`:

```dart
timeSlotController.loadRawTimeSlots(
  staffId:         bookingData.staffId!,
  date:            bookingData.selectedDate!,
  serviceDuration: bookingData.totalDuration ?? 30,
);
```

The controller:
1. Calls `GET /staff/slots/{staffId}?date={date}`
2. Parses the response into three `RawTimeSlot` lists:
   - `rawMorningSlots`
   - `rawAfternoonSlots`
   - `rawEveningSlots`
3. Each list is sorted by `startTime` ascending.

> **Note:** `serviceDuration` is accepted as a parameter but is **not used** during raw slot loading — it is only used during manual selection (see §4.2). The raw slots are always loaded as individual 15-min units.

### 4.2 Manual Slot Selection (`_handleSlotSelection` in `TimeSlotScreen`)

When the user taps a slot chip:

```
User taps slot X
    │
    ├─ Is slot booked?  → reject (no-op)
    ├─ Is slot in past? → reject (no-op, strikethrough shown)
    │
    ▼
slotsNeeded = ceil(totalDuration / 15)

Combine all raw slots (morning + afternoon + evening) into one list
Find index of tapped slot in combined list

Loop i = 0 to slotsNeeded - 1:
    currentSlot = allSlots[clickedIndex + i]
    ├─ Out of bounds?          → canSelect = false, break
    ├─ isBooked?               → canSelect = false, break
    ├─ isSlotInPast?           → canSelect = false, break
    └─ i > 0: previousSlot.endTime != currentSlot.startTime?
                               → canSelect = false, break (gap detected)
    Collect currentSlot.id into newSelectedIds

If canSelect == true:
    selectedStartSlot = firstSlot
    selectedSlotIds   = newSelectedIds
    selectedTimeRange = "10:00 AM - 10:30 AM"
Else:
    Show snackbar: "Not enough consecutive available slots for X minutes"
```

**Visual states of a slot chip:**

| State | Background | Border | Text |
|---|---|---|---|
| Available | White | Grey | Black |
| Selected (start) | Primary tint | Primary (2px) | Primary, bold |
| Selected (continuation) | Primary tint | Primary 50% | Primary |
| Booked | Grey[200] | Grey[300] | Grey |
| Past (today only) | Grey[200] | Grey[300] | Grey + strikethrough + clock icon |

### 4.3 Past-Slot Filtering (today only)

```dart
bool _isSlotInPast(RawTimeSlot slot) {
  if (!_isToday()) return false;
  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;
  final slotStart = _parseTimeToMinutes(slot.startTime);
  return slotStart <= currentMinutes;
}
```

If **all** slots are in the past, the screen shows a "No Available Slots" empty state with a "Select Different Date" button.

### 4.4 Confirming the Selection

When the user taps **Continue** in the bottom bar:

```dart
final updatedBookingData = bookingData.copyWith(
  startTime: startDateTime.toIso8601String(),  // from first selected slot
  endTime:   endDateTime.toIso8601String(),    // from last selected slot
  slotIds:   selectedSlotIds,                  // all slot IDs
);
Get.toNamed(BookingReviewScreen.routeName, arguments: updatedBookingData);
```

---

## 5. Check-In Flow — Step by Step

```
InitialScreen
    │  (tap "Check-In" — only enabled when outlet is open)
    │  userController.isUserChecking = true
    ▼
ServiceSelectionScreen          ← same screen as appointment
    │  BookingData built with services list + totalDuration
    ▼
BarberScreen                    ← user picks staff
    │  isUserChecking == true → _handleCheckInSlotSelection()
    │  NO calendar screen — date is always TODAY
    ▼
[Auto slot selection runs in background]
    │
    ├─ Slot found  → BookingReviewScreen (slot pre-filled)
    └─ No slots    → "No Slots Available" dialog
    ▼
BookingReviewScreen             ← customer details + consent
    ▼
POST /appointment/checkin
    ▼
AppointmentConfirmationScreen
```

### 5.1 Auto Slot Selection (`_handleCheckInSlotSelection` in `BarberScreen`)

This is the key difference from the appointment flow. The user **never sees a slot picker** — the system finds the best slot automatically.

```dart
Future<void> _handleCheckInSlotSelection(String? staffId, String staffName) async {
  // 1. Load today's raw slots
  await timeSlotController.loadRawTimeSlots(
    staffId:         staffId,
    date:            DateTime.now(),   // always today
    serviceDuration: bookingData.totalDuration ?? 15,
  );

  // 2. Find nearest available slot
  TimeSlot? nearestSlot = _findNearestAvailableSlot();

  if (nearestSlot != null) {
    // 3a. Slot found — skip calendar + time slot screens entirely
    final updatedBookingData = bookingData.copyWith(
      staffId:      staffId,
      staffName:    staffName,
      selectedDate: DateTime.now(),
      startTime:    nearestSlot.startTime,
      endTime:      nearestSlot.endTime,
      slotIds:      nearestSlot.slotIds,
    );
    Get.toNamed(BookingReviewScreen.routeName, arguments: updatedBookingData);
  } else {
    // 3b. No slots — show dialog
    _showNoSlotsAvailableDialog(staffName);
  }
}
```

A loading overlay (`"Finding available time slot..."`) is shown while the API call runs.

### 5.2 Finding the Nearest Available Slot (`_findNearestAvailableSlot`)

```
slotsNeeded = ceil(totalDuration / 15)

Combine all raw slots (morning + afternoon + evening) into one list
Sort by startTime ascending

For each slot i in allRawSlots:
    Parse slot i's startTime as DateTime (today's date + HH:mm)

    ├─ slotStartTime <= now?  → skip (already started or past)
    ├─ isBooked?              → skip
    │
    └─ Try to collect slotsNeeded consecutive slots from i:
        For j = 1 to slotsNeeded - 1:
            ├─ i+j out of bounds?                          → canBook = false
            ├─ allSlots[i+j-1].endTime != allSlots[i+j].startTime?  → canBook = false (gap)
            └─ allSlots[i+j].isBooked?                     → canBook = false
            Collect allSlots[i+j].id

        If canBook == true AND collected slotsNeeded IDs:
            Build TimeSlot {
              startTime: slotStartTime.toIso8601String(),
              endTime:   slotEndTime.toIso8601String(),
              slotIds:   [id1, id2, ...],
            }
            RETURN this slot  ← first match wins (nearest future slot)

Return null  ← no valid slot found
```

**Important:** The algorithm finds the **first** (earliest) future slot that has enough consecutive unbooked 15-min slots to cover the total service duration. It does not try to optimize for any other criteria.

### 5.3 No Slots Available Dialog

When `_findNearestAvailableSlot()` returns `null`, a dialog is shown:

- Title: "No Slots Available"
- Body: `All slots are occupied of "{staffName}" for today.`
- Button: "Book Later" — dismisses the dialog, user stays on BarberScreen

---

## 6. Outlet Open/Closed Gate (Check-In Only)

Before the user can even tap Check-In, the outlet status is checked.

**File:** `lib/services/appointment/outlet_status_repo.dart`  
**Controller:** `lib/ui/ititial/controller/initial_controller.dart`

```
GET /outlet/status
Response: { data: { openTime: "HH:mm:ss", closeTime: "HH:mm:ss" } }
```

**Caching strategy (SharedPreferences):**

| Key | Purpose |
|---|---|
| `outlet_status_cache` | JSON with openTime/closeTime |
| `outlet_status_cache_date` | Date of cache (yyyy-MM-dd) |
| `outlet_session_call_count` | Calls made since login (max 2) |
| `outlet_daily_call_count` | Calls made today (max 2) |
| `outlet_daily_call_date` | Date of daily counter |

Call priority:
1. `forceRefresh = true` → always hits API
2. Session calls < 2 → hits API (post-login)
3. Daily calls < 2 + no fresh cache → hits API (scheduled)
4. Fresh cache exists → uses cache
5. Fallback → hits API once more

The Check-In card on `InitialScreen` is **greyed out and disabled** when `isOutletOpen == false`. Tapping it shows a snackbar: `"Check-In is unavailable right now. Opens at {openTime}."`.

A `Timer.periodic(60 seconds)` re-evaluates the open state every minute. A mid-day scheduled call refreshes the outlet status at the midpoint between open and close times.

---

## 7. Booking API Payloads

### Appointment (`POST /appointment`)
```json
{
  "tenantId":   "...",
  "outletId":   "...",
  "staffId":    "...",
  "serviceIds": ["svc-id-1", "svc-id-2"],
  "slotIds":    ["slot-id-1", "slot-id-2"],
  "date":       "2026-05-01",
  "isWalkIn":   false,
  "startTime":  "10:00",
  "customer": {
    "first_name":    "John",
    "last_name":     "Doe",
    "email":         "john@example.com",
    "phone":         "+11234567890",
    "gender":        "",
    "date_of_birth": ""
  }
}
```

### Check-In (`POST /appointment/checkin`)
```json
{
  "tenantId":   "...",
  "outletId":   "...",
  "staffId":    "...",
  "serviceIds": ["svc-id-1"],
  "slotIds":    ["slot-id-1", "slot-id-2"],
  "date":       "2026-05-01",
  "startTime":  "10:00",
  "customer": {
    "first_name": "John",
    "last_name":  "Doe",
    "email":      "john@example.com",
    "phone":      "+11234567890"
  }
}
```

The only structural differences between the two payloads:
- Different API endpoint
- Appointment has `"isWalkIn": false` and `gender`/`date_of_birth` fields
- Check-In date is always today; appointment date is user-selected

---

## 8. What Is Checked vs What Is Not

### ✅ Currently Checked

| Check | Where |
|---|---|
| Slot is booked (`isBooked == true`) | `_handleSlotSelection`, `_findNearestAvailableSlot` |
| Slot is in the past (today only) | `_isSlotInPast`, `_findNearestAvailableSlot` |
| Consecutive slot continuity (`prevEnd == currStart`) | Both selection methods |
| Enough slots exist for service duration | Both selection methods |
| Outlet is open before allowing check-in | `InitialScreen` / `InitialScreenController` |
| Staff is selected before check-in proceeds | `_handleCheckInSlotSelection` (null check) |

### ❌ Currently NOT Checked / Known Gaps

| Gap | Impact | Location |
|---|---|---|
| **Check-in: no staff = blocked** — if user taps Continue without selecting a staff member, a snackbar says "Please select a specific service provider for check-in" but the UX could be clearer | Minor UX | `_handleCheckInSlotSelection` |
| **`BookingData.serviceDuration`** (single service field) is still present but unused — the actual duration comes from `totalDuration` computed from `services` list | Stale field, potential confusion | `book_appointment_model.dart` |
| **`BookingData.serviceId` / `serviceName` / `servicePrice`** are single-service legacy fields — the real data is in `services: List<ServiceDetails>` | Stale fields | `book_appointment_model.dart` |
| **No real-time slot refresh** — if another user books a slot between the time slots are loaded and the user confirms, the API will reject the booking. There is no optimistic lock or re-validation before submission | Race condition | `TimeSlotScreen`, `_handleCheckInSlotSelection` |
| **Cross-midnight slots** — if `endTime` is `"00:xx"` (past midnight), the consecutive check `prevEnd == currStart` will still work string-wise, but `_isSlotInPast` and `_findNearestAvailableSlot` do not handle midnight rollover | Edge case | `time_slot.dart`, `barber_screen.dart` |
| **Check-in: no manual slot override** — if the auto-selected slot is not ideal (e.g., user wants a later slot), there is no way to change it without going back and re-selecting staff | UX limitation | `barber_screen.dart` |
| **`loadRawTimeSlots` `serviceDuration` param is unused** — the parameter is accepted but `_parseRawTimeSlots` ignores it; grouping only happens in the legacy `loadTimeSlots` path | Dead parameter | `time_slot_controller.dart` |

---

## 9. File Reference Map

| File | Role |
|---|---|
| `lib/model/book_appointment_model.dart` | `BookingData` — data carrier between screens |
| `lib/ui/pickering/controller/time_slot_controller.dart` | Loads + parses raw slots; `RawTimeSlot` and `TimeSlot` classes |
| `lib/ui/pickering/view/time_slot.dart` | Manual slot selection UI (appointment only) |
| `lib/ui/pickering/view/barber_screen.dart` | Staff selection + **check-in auto slot logic** |
| `lib/ui/pickering/view/calendar_screen.dart` | Date picker (appointment only) |
| `lib/ui/pickering/view/service_selection_screen_2.dart` | Service selection (shared by both flows) |
| `lib/ui/pickering/controller/service_selection_controller.dart` | Service state; `getBookingData()` builds initial `BookingData` |
| `lib/ui/pickering/controller/review_confirm_controller.dart` | `createBooking()` — sends appointment or check-in API call |
| `lib/services/appointment/check_in_repo.dart` | Low-level check-in HTTP call |
| `lib/services/appointment/outlet_status_repo.dart` | Outlet open/close status with caching |
| `lib/ui/ititial/controller/initial_controller.dart` | Outlet status polling + open-state evaluation |
| `lib/ui/ititial/view/initial_screen.dart` | Home screen — appointment vs check-in entry point |

---

## 10. Flow Comparison Summary

| Step | Appointment | Check-In |
|---|---|---|
| Entry flag | `isUserChecking = false` | `isUserChecking = true` |
| Service selection | Manual (ServiceSelectionScreen) | Manual (same screen) |
| Staff selection | Manual (BarberScreen) | Manual (BarberScreen) |
| Date selection | Manual (CalendarSelectionScreen) | **Auto = today** |
| Slot selection | **Manual** (TimeSlotScreen) | **Auto** (nearest future slot) |
| Slot screen shown | Yes | No |
| API endpoint | `POST /appointment` | `POST /appointment/checkin` |
| Outlet gate | No | Yes — disabled if outlet closed |
