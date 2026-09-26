import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

// Server side of Daniel, the voice caddie.
//
// The app used to call Groq (speech-to-text, shot extraction, coaching) and
// ElevenLabs (Daniel's voice) directly with keys bundled into the APK. The
// keys now live only in this function's secrets (GROQ_API_KEY,
// ELEVENLABS_API_KEY).
//
// Two tasks, both for signed-in users only:
//   log_shot  audio (base64 m4a) -> { transcript, shot, feedback }
//   speak     Daniel's reply text -> { audio_base64 } (mp3)
//
// Prompts live here. The player's name and handicap are read from their own
// profile rather than taken from the request.

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? ""
const ELEVENLABS_API_KEY = Deno.env.get("ELEVENLABS_API_KEY") ?? ""

const WHISPER_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
const CHAT_URL = "https://api.groq.com/openai/v1/chat/completions"
const VOICE_ID = "onwK4e9ZLuTAKqWW03F9" // "Daniel" – British, calm
const TTS_URL = `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`

const MAX_AUDIO_BASE64_CHARS = 4_000_000 // ~3 MB, a few minutes of AAC
const MAX_SPEAK_CHARS = 600 // Daniel answers in 2–3 sentences
const MAX_RECENT_SHOTS = 10

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const json = (payload: unknown, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })

const EXTRACT_PROMPT = `
You are a golf shot data extractor for a mobile app called Score Caddie, used by golfers on the driving range in Kenya.
Your job is to extract structured shot data from a golfer's voice transcript.
ALWAYS return valid JSON only. No explanation, no preamble, no markdown.

Extract these fields:
- club: normalize to standard names ("driver", "3 wood", "5 wood", "7 wood", "hybrid", "2 iron", "3 iron", "4 iron", "5 iron", "6 iron", "7 iron", "8 iron", "9 iron", "pitching wedge", "gap wedge", "sand wedge", "lob wedge", "putter").
- distance: yards as integer. If player says meters, convert (meters * 1.094).
- distance_confidence: "exact" | "approximate" | "unknown"
- shape: "straight", "draw", "fade", "hook", "slice", "push", "pull".
- trajectory: "low", "normal", "high"
- quality: "great" (pure/flushed), "good" (solid), "okay" (not bad), "miss" (fat/thin/shank)
- notes: extra detail, max 10 words.

Example Input: "hit my 7 iron about 150 yards, slight fade"
Example Output: {"club": "7 iron", "distance": 150, "distance_confidence": "approximate", "shape": "fade", "trajectory": null, "quality": null, "notes": null}
`

const coachPrompt = (name: string, handicap: string) => `
You are Daniel — an experienced, sharp-witted golf caddie and coach inside the Score Caddie app.
You are standing on the driving range in Kenya with the player RIGHT NOW, between shots.
You speak with quiet authority. Direct. Knowledgeable. Max 2-3 sentences.

PLAYER PROFILE:
- Name: ${name}
- Handicap: ${handicap}

YOUR PERSONALITY:
- Name ROOT causes for misses (one fix only).
- Conversational, not textbook.
- Detect patterns over 3+ shots.
- Use "you", be specific. No generic "well done".

RULES:
- NO markdown, NO bullet points.
- Spoken caddie language.
- Only talk about golf. If the transcript isn't about a golf shot, say so briefly.
`

function decodeBase64(b64: string): Uint8Array {
  const bin = atob(b64)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
  return bytes
}

function encodeBase64(bytes: Uint8Array): string {
  let bin = ""
  const chunk = 0x8000
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk))
  }
  return btoa(bin)
}

async function groqChat(body: Record<string, unknown>): Promise<string> {
  const res = await fetch(CHAT_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${GROQ_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  })
  if (!res.ok) {
    console.error("Groq chat error", res.status, await res.text())
    throw new Error("chat failed")
  }
  const data = await res.json()
  return String(data?.choices?.[0]?.message?.content ?? "")
}

async function logShot(
  body: Record<string, unknown>,
  profile: { name: string; handicap: string },
) {
  const audio = String(body.audio_base64 ?? "")
  if (!audio || audio.length > MAX_AUDIO_BASE64_CHARS) return json({ error: "Invalid audio" }, 400)

  // 1. Voice -> text
  const form = new FormData()
  form.append("model", "whisper-large-v3-turbo")
  form.append("language", "en")
  form.append("response_format", "text")
  form.append("file", new Blob([decodeBase64(audio)], { type: "audio/mp4" }), "shot.m4a")
  const whisper = await fetch(WHISPER_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${GROQ_API_KEY}` },
    body: form,
  })
  if (!whisper.ok) {
    console.error("Whisper error", whisper.status, await whisper.text())
    return json({ error: "Couldn't hear that" }, 502)
  }
  const transcript = (await whisper.text()).trim().slice(0, 1000)
  if (!transcript) return json({ error: "Couldn't hear that" }, 422)

  // 2. Text -> shot data
  let shot: Record<string, unknown> = {}
  try {
    shot = JSON.parse(await groqChat({
      model: "llama-3.1-8b-instant",
      temperature: 0.1,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: EXTRACT_PROMPT },
        { role: "user", content: transcript },
      ],
    }))
  } catch (_) {
    shot = { notes: transcript.slice(0, 60) }
  }

  // 3. Daniel's feedback
  const recent = Array.isArray(body.recent_shots) ? body.recent_shots.slice(-MAX_RECENT_SHOTS) : []
  const feedback = (await groqChat({
    model: "llama-3.3-70b-versatile",
    temperature: 0.7,
    max_tokens: 150,
    messages: [
      { role: "system", content: coachPrompt(profile.name, profile.handicap) },
      {
        role: "user",
        content: `CURRENT SHOT: ${JSON.stringify(shot)}. RECENT SESSION: ${JSON.stringify(recent).slice(0, 2000)}. Give feedback.`,
      },
    ],
  })).trim()

  return json({ transcript, shot, feedback })
}

async function speak(body: Record<string, unknown>) {
  if (!ELEVENLABS_API_KEY) return json({ error: "Voice is not configured" }, 503)
  const text = String(body.text ?? "").replaceAll("*", "").replaceAll("_", "").trim()
  if (!text || text.length > MAX_SPEAK_CHARS) return json({ error: "Invalid text" }, 400)

  const res = await fetch(TTS_URL, {
    method: "POST",
    headers: { "xi-api-key": ELEVENLABS_API_KEY, "Content-Type": "application/json", accept: "audio/mpeg" },
    body: JSON.stringify({
      text,
      model_id: "eleven_flash_v2_5",
      voice_settings: { stability: 0.5, similarity_boost: 0.8 },
    }),
  })
  if (!res.ok) {
    console.error("ElevenLabs error", res.status, await res.text())
    return json({ error: "Voice failed" }, 502)
  }
  return json({ audio_base64: encodeBase64(new Uint8Array(await res.arrayBuffer())) })
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  // verify_jwt accepts the anon key too, so require a real signed-in user.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) return json({ error: "Sign in required" }, 401)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: "Invalid JSON" }, 400)
  }

  try {
    switch (String(body.task ?? "")) {
      case "log_shot": {
        if (!GROQ_API_KEY) return json({ error: "Daniel is not configured" }, 503)
        const { data: row } = await supabase
          .from("User")
          .select('name, "handicapIndex"')
          .eq("id", user.id)
          .maybeSingle()
        return await logShot(body, {
          name: String(row?.name ?? "the player").slice(0, 60),
          handicap: row?.handicapIndex != null ? String(row.handicapIndex) : "unknown",
        })
      }
      case "speak":
        return await speak(body)
      default:
        return json({ error: "Unknown task" }, 400)
    }
  } catch (e) {
    console.error("voice-coach failure", e)
    return json({ error: "Daniel is quiet right now" }, 502)
  }
})
