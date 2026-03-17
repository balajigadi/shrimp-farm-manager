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
