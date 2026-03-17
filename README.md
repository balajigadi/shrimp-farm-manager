# Shrimp Farm Manager

Flutter app for managing shrimp/prawn farms. Tracks ponds, water quality, feed, growth, mortality, expenses, and generates simple reports.

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
- **Localization**
  - English and తెలుగు (Telugu)
  - In‑app language switch under **Reports → Settings → Language**
- **Alerts (MVP)**
  - Local notifications (no backend) for:
    - Feed reminders (4x per day)
    - Daily water test
    - Weekly growth sampling
    - Daily mortality check
  - Test alerts from **Settings** or Alerts screen (bell icon).

## Getting started

```bash
flutter pub get
flutter run

Make sure you have valid Firebase configuration files for your own project:

android/app/google-services.json
ios/Runner/GoogleService-Info.plist
These files are not committed; use your own keys.

Tech stack
Flutter
Firebase Core + Cloud Firestore
flutter_local_notifications + timezone
fl_chart
flutter_localizations + intl

flutter pub get
flutter run
