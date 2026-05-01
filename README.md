# AaravPOS — Flutter Kiosk App

A self-service kiosk application built with Flutter for managing appointments and walk-in check-ins at a salon or service outlet. Customers can browse services, select a staff member, pick a date and time slot, fill in their details, sign consent forms, and confirm a booking — all from a single touch-screen device.

---

## Features

- **Appointment booking** — full flow: services → staff → date → slot → review → confirm
- **Walk-in check-in** — auto-selects today's nearest available slot after staff selection
- **Outlet status** — home screen checks live open/close window (time-of-day based) with pull-to-refresh
- **Consent forms** — digital signature capture per service that requires consent
- **Customer lookup** — phone-number search with auto-fill from existing customer records
- **Session state management** — downstream selections clear automatically on back-navigation
- **Responsive layout** — adapts between mobile and tablet/desktop breakpoints
- **Secure token storage** — JWT persisted in platform secure storage, auto-login on restart

---

## Tech Stack

| Layer | Library | Version |
|---|---|---|
| UI Framework | Flutter | 3.41.8 (stable) |
| Language | Dart | 3.11.5 |
| State Management | flutter_bloc + equatable | 8.1.6 / 2.0.5 |
| Navigation | go_router | 14.6.2 |
| HTTP Client | dio | 5.7.0 |
| Dependency Injection | get_it | 8.0.2 |
| Secure Storage | flutter_secure_storage | 9.2.2 |
| Animations | lottie | 3.1.3 |
| Image Caching | cached_network_image | 3.4.1 |
| Calendar | table_calendar | 3.1.2 |
| Grid Layout | flutter_staggered_grid_view | 0.7.0 |
| Signature Capture | signature | 5.5.0 |
| Country Picker | country_picker | 2.0.26 |
| Shimmer Loading | shimmer | 3.0.0 |
| Internationalisation | intl | 0.20.1 |
| Code Generation | freezed + json_serializable | 2.5.7 / 6.8.0 |

---

## Project Structure

```
lib/
├── app.dart                        # Root widget, BlocProviders
├── main.dart                       # Entry point
├── core/
│   ├── constants/                  # App-wide constants and spacing
│   ├── network/                    # Dio client and interceptors
│   ├── router/                     # GoRouter config and route names
│   ├── storage/                    # SecureStorage wrapper
│   ├── theme/                      # AppTheme
│   └── utils/                      # Extensions, helpers
├── data/
│   ├── auth/                       # Auth remote data source
│   ├── booking/                    # Booking remote data source
│   └── ...                         # Other data sources
├── domain/
│   ├── model/                      # Pure data models (OutletStatus, SlotItem, …)
│   └── repo/                       # Repository interfaces
├── presentation/
│   ├── bloc/                       # BLoC classes (auth, session, booking, …)
│   └── screens/
│       ├── pages/                  # Full screens (HomeScreen, ServicesScreen, …)
│       └── widgets/                # Reusable screen-level widgets
└── shared/
    └── widgets/                    # App-wide widgets (AppShimmer, CommonAppBar, …)
```

---

## Prerequisites

| Tool | Minimum version |
|---|---|
| Flutter SDK | 3.41.x (stable) |
| Dart SDK | 3.11.x |
| Android Studio / Xcode | Latest stable |
| Android SDK | API 21+ |
| iOS Deployment Target | 13.0+ |

Install Flutter by following the [official guide](https://docs.flutter.dev/get-started/install).

---

## Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd aaravpos
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the API base URL

Open `lib/core/network/api_service.dart` (or the relevant constants file) and set your backend URL:

```dart
const String baseUrl = 'https://your-api-domain.com/api/';
```

### 4. Run code generation (if needed)

If you modify any `@freezed` or `@JsonSerializable` models, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Running the App

### Debug mode

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Specific device
flutter devices          # list connected devices
flutter run -d <device-id>
```

### Release mode (local testing)

```bash
flutter run --release
```

---

## Building

### Android APK

```bash
# Debug
flutter build apk --debug

# Release (signed)
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires macOS + Xcode)

```bash
flutter build ios --release
```

Then archive and distribute via Xcode or `xcodebuild`.

---

## Signing (Android)

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```
2. Create `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
3. Reference it in `android/app/build.gradle.kts` under `signingConfigs`.

---

## Environment Notes

- The app stores the auth token in platform secure storage — no `.env` file is needed at runtime.
- The outlet open/close check is purely time-of-day based (device clock). The date portion of API timestamps is ignored.
- Pull-to-refresh on the home screen re-fetches outlet status and re-evaluates the check-in availability.

---

## Flutter Version

```
Flutter 3.41.8 • channel stable
Dart   3.11.5
DevTools 2.54.2
```

To pin this version with FVM:

```bash
fvm install 3.41.8
fvm use 3.41.8
```
