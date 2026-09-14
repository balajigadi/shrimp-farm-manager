# Manual regression checklist

Use a physical Android phone (or emulator with Google speech services). Do not skip Confirm — voice must never save by itself.

Password for demo accounts: `Demo@123`

## Authentication

- [ ] Sign in as farmer (demo1)
- [ ] Sign out
- [ ] Sign in as supervisor (demo2) — farm tabs visible, no trader-only market posting
- [ ] Sign in as trader (demo3) — **no** Ponds tab, **no** Record Farm Activity
- [ ] Farmer with buyer-only intent (demo4) — market tab, **no** farm voice button
- [ ] Role routing after a fresh install / clear app data still reaches onboarding when needed

## Farmer — existing manual entry (must still work)

- [ ] Create a pond
- [ ] View pond on Pond Overview
- [ ] Manual feed entry (type, kg, tray) saves and appears in history
- [ ] Manual water entry requires all six parameters; missing values are not stored as 0
- [ ] Manual growth sample (ABW + survival; sample size optional)
- [ ] Manual mortality entry (including 0 / no mortality today)
- [ ] Expenses
- [ ] Reports (last 7 days)
- [ ] Alerts / notifications screen still opens

## Market

- [ ] Farmer feed of trader requirements (demo1 / demo4)
- [ ] Trader posts a requirement (demo3)
- [ ] Farmer interest flow (call / WhatsApp / interested count)

## Localization

- [ ] English UI
- [ ] Telugu UI
- [ ] Language switch in settings applies without restart issues on farm tabs

## Voice Farm Entry (farmer / supervisor with farm tabs)

Entry: Pond Overview → **Record Farm Activity** (microphone button). Add-pond FAB must still be present.

- [ ] Microphone permission accepted — listening UI appears
- [ ] Microphone permission denied — useful error, retry, **nothing saved**
- [ ] Speech recognition unavailable (if the device has no recognizer) — useful error
- [ ] English feed, e.g. `Pond 2 morning feed 45 kilos tray empty`
  - Feed type should be **missing** until you type it
  - Confirm disabled until pond, kg, feed type, tray are set
- [ ] English water, e.g. `Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 ammonia 0.05 hardness 120`
- [ ] Mixed Telugu-English feed, e.g. `Pond 2 lo 45 kg feed vesamu tray empty`
- [ ] Ambiguous pond (two ponds that both match “Pond 2”) — app asks you to pick; does not guess
- [ ] Edit a recognized value before save
- [ ] Cancel — no Firestore write
- [ ] Confirm — one FeedLog / PondLog / GrowthSample / MortalityLog in the **existing** screens
- [ ] Save failure (airplane mode after Confirm) — error, draft remains, no false success
- [ ] Retry after empty transcript
- [ ] Double-tap Confirm does not create two records
- [ ] Trader account never sees this entry point

## What not to expect in V1

- Unrestricted Telugu sentences
- Automatic save from speech
- OCR / lab-report photos
- Cloud LLM parsing
- Audio file stored in Firebase
