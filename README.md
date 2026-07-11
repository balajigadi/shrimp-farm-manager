# Shrimp Farm Manager

Flutter app for managing shrimp/prawn farms. Tracks ponds, water quality, feed, growth, mortality, expenses, and generates simple reports. Includes a **Market** feature for trader buyer requirements and farmer notifications.

## Features

- **Pond overview**
  - Multiple ponds per farm
  - Days of culture, average body weight, survival, FCR, biomass, harvest estimate
- **Daily operations**
  - Water quality logs (pH, salinity, ammonia, DO, temperature)
  - Feed logs (per pond or all ponds)
  - Growth sampling
  - Mortality logging
  - Expenses (feed, seed, labor, electricity, maintenance, other)
- **Reports**
  - Cycle summary (DOC, avg weight, biomass, FCR)
  - 7‑day feed and water summaries
  - Expense summary and simple profit estimate
- **Market**
  - Traders post buyer requirements by mandal
  - Farmers see matching requirements; tap **Interested** to contact via phone/WhatsApp
  - FCM push when new requirements match farmer region
- **Role-based onboarding**
  - Farmer (farm only, notifications only, or both)
  - Supervisor (farm tabs)
  - Trader (market + post requirements, phone OTP)
- **Localization**
  - English and తెలుగు (Telugu)
  - In‑app language switch under **Settings**
- **Alerts (MVP)**
  - Local notifications for feed, water, growth, mortality reminders
  - Test alerts from **Settings**

## Getting started

```bash
flutter pub get
flutter run
```

Make sure you have valid Firebase configuration files for your own project:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files are not committed; use your own keys.

## Tech stack

- Flutter
- Firebase Auth, Cloud Firestore, FCM, Cloud Functions
- `flutter_local_notifications` + `timezone`
- `fl_chart`
- `flutter_localizations` + `intl`

## Demo accounts

Password for all: `Demo@123`

| Email | Role |
|-------|------|
| `demo1@prawnfarm.com` | Farmer (both): ponds + Market |
| `demo2@prawnfarm.com` | Supervisor: ponds only |
| `demo3@prawnfarm.com` | Trader: post requirements |
| `demo4@prawnfarm.com` | Farmer (notifications only): Market only |

Seed demo data:

```bash
cd tools
node demo_seed_per_user.js
```

## Firestore composite indexes (required)

Queries like **water logs** (`farmId` + `pondId` + `orderBy date`) and **market** (`region` + `status` + `expiresAt`) fail until indexes exist. If Logcat shows:

`The query requires an index. You can create it here: https://console.firebase.google.com/...`

**Fastest fix:** open that link in a browser → **Create index** → wait until status is **Enabled** (often a few minutes).

**Or deploy all indexes from this repo** (needs [Firebase CLI](https://firebase.google.com/docs/cli) and `firebase login`):

```bash
firebase use prawn-farm-app
firebase deploy --only firestore,firestore:indexes,functions
```

Index definitions live in `firestore.indexes.json`.

### Emulator: `Unable to resolve host firestore.googleapis.com`

That is a **DNS / network** issue on the emulator (no internet). Cold boot the AVD, toggle airplane mode off/on in the emulator, or confirm the host PC can reach Google. Firestore will not load until DNS works.

## Branch workflow

Do not push directly to `main`. Use feature branches and open a Pull Request on GitHub.
