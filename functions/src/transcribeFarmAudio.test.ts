import assert from "node:assert/strict";
import test from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import {
  MAX_AUDIO_BYTES,
  runTranscribeFarmAudio,
  validateTranscribeRequest,
  type OpenAiTranscriptionPort,
} from "./transcribeFarmAudio";

test("rejects empty payload", () => {
  assert.throws(
    () => validateTranscribeRequest({}),
    (err: unknown) => err instanceof HttpsError && err.code === "invalid-argument"
  );
});

test("rejects oversized audio", () => {
  const big = Buffer.alloc(MAX_AUDIO_BYTES + 1, 1).toString("base64");
  assert.throws(
    () =>
      validateTranscribeRequest({
        audioBase64: big,
        mimeType: "audio/mp4",
        durationMs: 1000,
      }),
    (err: unknown) => err instanceof HttpsError
  );
});

test("rejects duration over 20s", () => {
  assert.throws(
    () =>
      validateTranscribeRequest({
        audioBase64: Buffer.from("abc").toString("base64"),
        mimeType: "audio/mp4",
        durationMs: 20001,
      }),
    (err: unknown) => err instanceof HttpsError
  );
});

test("mocked openai success returns transcript only", async () => {
  const port: OpenAiTranscriptionPort = {
    async transcribe() {
      return "Feed Pond 2 45 kg tray empty";
    },
  };
  const result = await runTranscribeFarmAudio(
    {
      audioBase64: Buffer.from("fake-audio").toString("base64"),
      mimeType: "audio/mp4",
      durationMs: 1500,
      pondNames: ["Pond 2"],
      languages: ["en", "te"],
      prompt: "transcribe only",
      keywords: ["pond", "tray"],
    },
    port
  );
  assert.equal(result.transcript, "Feed Pond 2 45 kg tray empty");
  assert.equal(result.model, "gpt-transcribe");
  assert.equal(result.audioSha256.length, 64);
});

test("empty openai transcript fails", async () => {
  const port: OpenAiTranscriptionPort = {
    async transcribe() {
      return "   ";
    },
  };
  await assert.rejects(
    () =>
      runTranscribeFarmAudio(
        {
          audioBase64: Buffer.from("x").toString("base64"),
          mimeType: "audio/wav",
          durationMs: 500,
        },
        port
      ),
    (err: unknown) => err instanceof HttpsError
  );
});
