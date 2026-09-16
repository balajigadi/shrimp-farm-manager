/**
 * Authenticated farm audio → OpenAI gpt-transcribe → raw transcript only.
 * Never persist audio/transcript. Never expose OPENAI_API_KEY to clients.
 */
import { createHash } from "crypto";
import { defineSecret } from "firebase-functions/params";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import OpenAI, { toFile } from "openai";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

export const MAX_AUDIO_BYTES = 5_000_000;
export const MAX_DURATION_MS = 20_000;
export const ALLOWED_MIME = new Set([
  "audio/mp4",
  "audio/m4a",
  "audio/mpeg",
  "audio/mp3",
  "audio/wav",
  "audio/webm",
  "audio/x-m4a",
  "audio/aac",
]);

export type TranscribeFarmAudioRequest = {
  audioBase64?: string;
  mimeType?: string;
  durationMs?: number;
  pondNames?: string[];
  languages?: string[];
  prompt?: string;
  keywords?: string[];
};

export type OpenAiTranscriptionPort = {
  transcribe: (args: {
    buffer: Buffer;
    filename: string;
    mimeType: string;
    prompt: string;
    keywords: string[];
    languages: string[];
  }) => Promise<string>;
};

export function validateTranscribeRequest(data: TranscribeFarmAudioRequest): {
  buffer: Buffer;
  mimeType: string;
  durationMs: number;
  pondNames: string[];
  languages: string[];
  prompt: string;
  keywords: string[];
} {
  const audioBase64 = data.audioBase64;
  if (!audioBase64 || typeof audioBase64 !== "string") {
    throw new HttpsError("invalid-argument", "audioBase64 is required");
  }
  const mimeType = (data.mimeType || "").toLowerCase();
  if (!ALLOWED_MIME.has(mimeType)) {
    throw new HttpsError("invalid-argument", "unsupported mimeType");
  }
  const durationMs = Number(data.durationMs ?? 0);
  if (!Number.isFinite(durationMs) || durationMs < 0 || durationMs > MAX_DURATION_MS) {
    throw new HttpsError("invalid-argument", "durationMs exceeds limit");
  }
  let buffer: Buffer;
  try {
    buffer = Buffer.from(audioBase64, "base64");
  } catch {
    throw new HttpsError("invalid-argument", "invalid audioBase64");
  }
  if (buffer.length === 0 || buffer.length > MAX_AUDIO_BYTES) {
    throw new HttpsError("invalid-argument", "audio size out of range");
  }
  const pondNames = Array.isArray(data.pondNames)
    ? data.pondNames.map(String).slice(0, 40)
    : [];
  const languages = Array.isArray(data.languages)
    ? data.languages.map(String).slice(0, 5)
    : ["en"];
  const prompt =
    typeof data.prompt === "string" && data.prompt.trim()
      ? data.prompt.slice(0, 2000)
      : "Transcribe spoken prawn farm activity. Do not invent values. Do not output JSON.";
  const keywords = Array.isArray(data.keywords)
    ? data.keywords.map(String).slice(0, 80)
    : [];
  return { buffer, mimeType, durationMs, pondNames, languages, prompt, keywords };
}

export async function runTranscribeFarmAudio(
  data: TranscribeFarmAudioRequest,
  port: OpenAiTranscriptionPort
): Promise<{ transcript: string; model: string; audioSha256: string }> {
  const validated = validateTranscribeRequest(data);
  const audioSha256 = createHash("sha256").update(validated.buffer).digest("hex");
  const transcript = await port.transcribe({
    buffer: validated.buffer,
    filename: extensionForMime(validated.mimeType),
    mimeType: validated.mimeType,
    prompt: validated.prompt,
    keywords: validated.keywords,
    languages: validated.languages,
  });
  const trimmed = (transcript || "").trim();
  if (!trimmed) {
    throw new HttpsError("not-found", "empty transcript");
  }
  return { transcript: trimmed, model: "gpt-transcribe", audioSha256 };
}

function extensionForMime(mime: string): string {
  if (mime.includes("webm")) return "audio.webm";
  if (mime.includes("wav")) return "audio.wav";
  if (mime.includes("mpeg") || mime.includes("mp3")) return "audio.mp3";
  return "audio.m4a";
}

export function createOpenAiPort(apiKey: string): OpenAiTranscriptionPort {
  const client = new OpenAI({ apiKey });
  return {
    async transcribe({ buffer, filename, mimeType, prompt, keywords, languages }) {
      const file = await toFile(buffer, filename, { type: mimeType });
      const result = await client.audio.transcriptions.create({
        file,
        model: "gpt-transcribe",
        prompt,
        keywords,
        languages,
        response_format: "json",
      } as unknown as Parameters<typeof client.audio.transcriptions.create>[0]);
      if (typeof result === "string") return result;
      return (result as { text?: string }).text ?? "";
    },
  };
}

export const transcribeFarmAudio = onCall(
  {
    secrets: [openaiApiKey],
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }
    const started = Date.now();
    try {
      const port = createOpenAiPort(openaiApiKey.value());
      const result = await runTranscribeFarmAudio(
        (request.data ?? {}) as TranscribeFarmAudioRequest,
        port
      );
      console.info(
        JSON.stringify({
          fn: "transcribeFarmAudio",
          uid: request.auth.uid,
          ms: Date.now() - started,
          model: result.model,
          audioSha256: result.audioSha256,
        })
      );
      return { transcript: result.transcript, model: result.model };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      console.error(
        JSON.stringify({
          fn: "transcribeFarmAudio",
          uid: request.auth.uid,
          ms: Date.now() - started,
          error: "transcription_failed",
        })
      );
      throw new HttpsError("internal", "transcription failed");
    }
  }
);
