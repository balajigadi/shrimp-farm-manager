# OpenAI Transcription Docs Note

The official recommended transcription model for this pilot is
`gpt-transcribe`.

Use Firebase Cloud Functions to call `POST /v1/audio/transcriptions`. The
request can include `prompt`, `keywords`, and `languages`; this app sends farm
vocabulary, pond names, and the preferred English/Telugu language hints.

Supported audio formats include `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`,
and `webm`. OpenAI's audio upload limit is 25 MB; this pilot enforces a smaller
5 MB and 20 second limit in the callable function.
# OpenAI transcription docs check (pilot)

Checked official OpenAI documentation before implementing the cloud provider.

## Model

- **Recommended for file transcription:** `gpt-transcribe`
  ([Transcription guide](https://developers.openai.com/api/docs/guides/transcription),
  [model card](https://developers.openai.com/api/docs/models/gpt-transcribe))
- Endpoint: `POST /v1/audio/transcriptions`
- Older snapshots (`gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `whisper-1`) remain
  available but are **not** the recommended starting models for a new integration.

## Context hints (`gpt-transcribe`)

- `prompt` — free-form domain context (not a task restatement)
- `keywords` — literal terms that may appear (hints only; do not invent)
- `languages` — list of expected languages (e.g. `en`, `te`) instead of singular `language`

## Audio formats / limits

- Formats: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, `webm` (and related)
- Max upload size: **25 MB** (we enforce a much smaller limit server-side for farm utterances)

## This app

- Flutter never holds the OpenAI API key.
- Cloud Function `transcribeFarmAudio` calls OpenAI with model **`gpt-transcribe`**.
- Output is **raw transcript text only** — farm parsing stays in `FarmSpeechNormalizer` +
  `RuleBasedFarmActivityParser`.
