# Cloud Functions — Market requirement notifications

## What it does

`onRequirementCreated` fires when a document is created in `requirements/{id}`:

1. **Rate limit** — counts today's posts for `traderId` (Asia/Kolkata midnight). If **> 5**, sets `notificationsSkipped: true` and `skipReason: "daily_cap_exceeded"` on the requirement (no FCM).
2. **Farmer lookup** — queries `userSettings` where `region` **equals** one of the requirement's `region` array values (`where('region', 'in', ...)`), matching the inverse of client `arrayContains`.
3. **Filters** — `role == farmer`, `farmerIntent` in `buyer_notifications` | `both`, non-empty `fcmToken`, excludes posting trader.
4. **FCM** — `sendEachForMulticast` in batches of 500; clears invalid tokens via `cleanupInvalidTokens.ts`.

## Schema reference (from Flutter)

| Collection | Field | Type |
|------------|-------|------|
| `userSettings/{uid}` | `region` | **string** |
| `userSettings/{uid}` | `fcmToken` | **string** |
| `userSettings/{uid}` | `role` | string |
| `userSettings/{uid}` | `farmerIntent` | string |
| `requirements/{id}` | `region` | **string[]** |
| `requirements/{id}` | `traderId`, `traderName`, `quantityNeeded`, `unit`, `countRange.{min,max}`, `status`, `createdAt` | see `requirement_model.dart` |

## Firebase plan

**Blaze (pay-as-you-go) required.** Cloud Functions and FCM admin sends do not run on the Spark free plan.

## Deploy

From project root:

```powershell
cd C:\Projects\android\develop\prawn_farm_app\functions
npm install
cd ..
npx.cmd firebase deploy --only functions
```

Deploy everything (rules + indexes + functions):

```powershell
npx.cmd firebase deploy --only firestore,functions
```

## Local testing (emulators)

### 1. Install & build

```powershell
cd C:\Projects\android\develop\prawn_farm_app\functions
npm install
npm run build
```

### 2. Start Firestore + Functions emulators

```powershell
cd C:\Projects\android\develop\prawn_farm_app
npx.cmd firebase emulators:start --only firestore,functions
```

UI: http://localhost:4000

### 3. Seed a farmer `userSettings` doc

In the Firestore emulator UI (or a script), create:

`userSettings/farmer-test-uid`

```json
{
  "uid": "farmer-test-uid",
  "role": "farmer",
  "farmerIntent": "buyer_notifications",
  "region": "Bhimavaram",
  "fcmToken": "fake-token-for-emulator-test"
}
```

Use a **real FCM registration token** from a debug device if you want to verify delivery; otherwise the function still runs and logs multicast results.

### 4. Trigger the function

Create a document in `requirements` (emulator UI or Admin SDK):

```json
{
  "traderId": "trader-uid-1",
  "traderName": "Demo Trader",
  "traderPhone": "+919999999999",
  "countRange": { "min": 40, "max": 50 },
  "quantityNeeded": 500,
  "unit": "kg",
  "region": ["Bhimavaram"],
  "status": "open",
  "createdAt": "<server timestamp>",
  "expiresAt": "<future timestamp>"
}
```

Watch the **Functions** emulator logs for `onRequirementCreated` and `FCM multicast complete`.

### 5. Test daily cap

Create **6** requirements the same day with the same `traderId`. The 6th should log `daily_cap_exceeded` and write `notificationsSkipped` on the doc.

### 6. Node one-liner (optional)

With emulators running (`FIRESTORE_EMULATOR_HOST=localhost:8080`):

```powershell
cd C:\Projects\android\develop\prawn_farm_app\tools
$env:FIRESTORE_EMULATOR_HOST="localhost:8080"
node -e "const admin=require('firebase-admin');admin.initializeApp({projectId:'prawn-farm-app'});admin.firestore().collection('requirements').add({traderId:'t1',traderName:'T',traderPhone:'+911',countRange:{min:40,max:50},quantityNeeded:500,unit:'kg',region:['Bhimavaram'],status:'open',createdAt:admin.firestore.FieldValue.serverTimestamp(),expiresAt:admin.firestore.Timestamp.fromDate(new Date(Date.now()+86400000))}).then(r=>console.log('created',r.id));"
```

## Flutter follow-up

`FcmService` saves tokens but does **not** handle notification taps or route to `MarketScreen` with `requirementId`. Add `FirebaseMessaging.onMessageOpenedApp` / `getInitialMessage` when ready.

## Notification channel (Android)

Create `market_requirements` channel in the Flutter app before relying on `android.notification.channelId` in the payload.
