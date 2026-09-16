# Transcription provider pilot

Practical Platform vs Cloud comparison for Prawn Farm Manager voice entry.

## Pipeline (unchanged farm logic)

```
TranscriptionProvider → RAW TEXT → FarmSpeechNormalizer → RuleBasedFarmActivityParser
→ draft → editable confirmation → Confirm → Firestore
```

Cloud path: mic record → Firebase `transcribeFarmAudio` → OpenAI `gpt-transcribe` → raw text.

## Setup

1. `firebase functions:secrets:set OPENAI_API_KEY`
2. Deploy functions including `transcribeFarmAudio`
3. Debug Settings → Voice engine experiment → Platform / OpenAI / Auto
4. Record the same intended phrase with both providers when possible

## Manual comparison table (fill on device)

| ID | What farmer said | Language style | Provider | Transcript | Activity? | Pond? | Numbers? | Tray? | Corrections | Latency | Notes |
|----|------------------|----------------|----------|------------|-----------|-------|----------|-------|-------------|---------|-------|
| 1 | Feed Pond 2 45 kgs tray empty | EN | platform | | | | | | | | |
| 2 | Feed Pond 2 45 kgs tray empty | EN | cloud | | | | | | | | |
| 3 | South Pond growth booster feed 20 kg tray full | EN | platform | | | | | | | | |
| 4 | South Pond growth booster feed 20 kg tray full | EN | cloud | | | | | | | | |
| 5 | Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 | EN | platform | | | | | | | | |
| 6 | Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 | EN | cloud | | | | | | | | |
| 7 | Pond 3 sample ABW 24 grams survival 85 percent | EN | platform | | | | | | | | |
| 8 | Pond 3 sample ABW 24 grams survival 85 percent | EN | cloud | | | | | | | | |
| 9 | Rendo pond lo 45 kg feed vesam tray empty | TE-EN | platform | | | | | | | | |
| 10 | Rendo pond lo 45 kg feed vesam tray empty | TE-EN | cloud | | | | | | | | |
| 11 | South pond lo growth booster 20 kg vesam tray lo konchem migilindi | TE-EN | platform | | | | | | | | |
| 12 | South pond lo growth booster 20 kg vesam tray lo konchem migilindi | TE-EN | cloud | | | | | | | | |
| 13 | Rendo pond lo pH 8.1 DO 5.2 undi | TE-EN | platform | | | | | | | | |
| 14 | Rendo pond lo pH 8.1 DO 5.2 undi | TE-EN | cloud | | | | | | | | |
| 15 | Pond 3 sample lo ABW 24 grams survival 85 percent | TE-EN | platform | | | | | | | | |
| 16 | Pond 3 sample lo ABW 24 grams survival 85 percent | TE-EN | cloud | | | | | | | | |
| 17 | Rendo pond lo 12 prawns chanipoyayi | TE-EN | platform | | | | | | | | |
| 18 | Rendo pond lo 12 prawns chanipoyayi | TE-EN | cloud | | | | | | | | |
| 19 | (real fail) expected Feed Pond 2 45… / heard Feed Pandu 245… | EN | platform | Feed Pandu 245 kgs Re enti | | | | | | | regression |
| 20 | South Point / C20 / prayful / stray full cases | EN | both | | | | | | | | regression |

## Privacy

- Record only after mic tap; visible listening state
- Temp audio deleted after success/fail/cancel
- No Firestore audio; no Storage upload for MVP
- OpenAI key only in Functions secret

## App Store privacy (later)

May need to disclose speech data processed by a third party (OpenAI) when Enhanced voice is enabled for production users.
