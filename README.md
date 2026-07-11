# prawn_farm_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firestore composite indexes (required)

Queries like **water logs** (`farmId` + `pondId` + `orderBy date`) fail until indexes exist. If Logcat shows:

`The query requires an index. You can create it here: https://console.firebase.google.com/...`

**Fastest fix:** open that link in a browser → **Create index** → wait until status is **Enabled** (often a few minutes).

**Or deploy all indexes from this repo** (needs [Firebase CLI](https://firebase.google.com/docs/cli) and `firebase login`):

```bash
cd prawn_farm_app
firebase use prawn-farm-app   # your project id
firebase deploy --only firestore:indexes
```

Index definitions live in `firestore.indexes.json`.

### Emulator: `Unable to resolve host firestore.googleapis.com`

That is a **DNS / network** issue on the emulator (no internet). Cold boot the AVD, toggle airplane mode off/on in the emulator, or confirm the host PC can reach Google. Firestore will not load until DNS works.
