import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

// Server-side Gemini proxy.
//
// The Gemini API key used to ship inside the mobile app (bundled .env), so
// anyone who unzipped the APK could bill the account. It now lives only in
// this function's secrets (GEMINI_API_KEY).
//
// Deliberately NOT a generic pass-through: prompts live here and only the
// named tasks below are accepted, so a signed-in user can't use this as a
// free general-purpose Gemini endpoint. Inputs are size-capped.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? ""
const MODEL = "gemini-2.5-flash"
const MAX_IMAGE_BASE64_CHARS = 8_000_000 // ~6 MB image

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const clip = (value: unknown, max: number) => String(value ?? "").slice(0, max)
const num = (value: unknown) => {
  const n = Number(value)
  return Number.isFinite(n) ? n : 0
}

type GeminiPart = { text: string } | { inline_data: { mime_type: string; data: string } }

function buildRequest(task: string, body: Record<string, unknown>):
  { parts: GeminiPart[]; json: boolean } | null {
  switch (task) {
    case "scan_scorecard": {
      const image = String(body.image_base64 ?? "")
      if (!image || image.length > MAX_IMAGE_BASE64_CHARS) return null
      const playerName = clip(body.player_name, 80)
      const clubName = clip(body.club_name, 120)
      const prompt = `
You are an expert golf scorecard reader. Your task is to analyze the scorecard image, find the scores for the specified player, and extract them.

PLAYER NAME TO FIND: ${playerName}
CLUB/COURSE: ${clubName}

INSTRUCTIONS:
1. Identify which row or column belongs to "${playerName}" using fuzzy string matching. If there are multiple player columns (e.g., Column A, B, C, D) or rows, look for the name written in the header/label.
2. If the name is not explicitly written but there's a player slot (e.g. "Player 1", "A"), match the most likely golfer row/column.
3. Determine the type of round based on the holes filled: 'full_18', 'front_9', or 'back_9'.
   - If scores are only written/filled for holes 1-9, round_type must be 'front_9', and you should only return holes 1-9 in the 'holes' list.
   - If scores are only written/filled for holes 10-18, round_type must be 'back_9', and you should only return holes 10-18 in the 'holes' list.
   - If scores are filled for both, round_type must be 'full_18', and you should return all 18 holes.
4. Extract the hole number (1-18), the par for each hole, and the score.
5. If a score is unreadable, blurred, or blank, return null for that hole's score. Do not guess.
6. Check for totals on the scorecard (Front 9 Total, Back 9 Total, Gross Total) and return them if present.
7. Assess your confidence (0.0 to 1.0) in the extraction accuracy. If the scorecard is very blurry, low contrast, or does not contain scores for the specified player, confidence should be below 0.4.
8. Add warnings if you find suspicious numbers, double strokes, or markings that might be hard to read.

Return a JSON object conforming exactly to this schema:
{
  "player_slot": "String representing player slot identified on card (e.g. 'Player A', 'Row 2')",
  "matched_name": "String representing the name matched on the card",
  "confidence": double (0.0 to 1.0),
  "round_type": "full_18" | "front_9" | "back_9",
  "holes": [ { "hole": integer (1-18), "par": integer, "score": integer or null } ],
  "front_9_total": integer or null,
  "back_9_total": integer or null,
  "gross_total": integer or null,
  "warnings": ["String of warnings if any"]
}

Output must be raw JSON conforming to this schema.
`
      return {
        parts: [{ text: prompt }, { inline_data: { mime_type: "image/jpeg", data: image } }],
        json: true,
      }
    }

    case "practice_session": {
      const prompt = `
You are Daniel, an elite AI Golf Caddie and Data Analyst. Analyze this player's practice session data and provide sharp, professional insights.

SESSION TYPE: ${clip(body.session_type, 80)}
TOTAL BALLS: ${num(body.total_balls)}

CLUB PERFORMANCE DATA:
${clip(body.stats_summary, 2000)}

INSTRUCTIONS:
1. Provide a "Session Verdict" (1 concise sentence).
2. Identify the "Struggling Club" if any, and why based on data.
3. Identify the "Pure Club" of the session.
4. Give one specific biomechanical tip or drill adjustment for the next session.
5. Use the "Golf Brain" knowledge: Irons need descending blows, Woods need sweeping.
6. Keep it encouraging but data-driven and elite.
`
      return { parts: [{ text: prompt }], json: false }
    }

    case "performance": {
      const playerName = clip(body.player_name, 80)
      const prompt = `
You are Daniel, an elite AI Golf Caddie and Data Analyst.
Analyze this player's recent performance trends and provide sharp, professional insights.

PLAYER: ${playerName}
ROUNDS PLAYED: ${num(body.rounds_played)}
FAIRWAY HIT %: ${Math.round(num(body.fairway_pct))}%
GIR %: ${Math.round(num(body.gir_pct))}%
PUTTS PER ROUND: ${num(body.putts_per_round).toFixed(1)}
SCORE TREND: ${clip(body.score_trend, 20) || "Stable"}

INSTRUCTIONS:
1. Start with a direct address: "${playerName}, ..."
2. Provide a 2-3 sentence high-level analysis of their game.
3. Identify their biggest strength from the data.
4. Give one specific "Pro Tip" to lower their scores next week.
5. Tone: Elite, data-driven, encouraging, and sharp.
`
      return { parts: [{ text: prompt }], json: false }
    }

    default:
      return null
  }
}

const json = (payload: unknown, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  // verify_jwt only proves the token was issued by this project. The anon
  // key passes that too, so require a real signed-in user.
  const authHeader = req.headers.get("Authorization") ?? ""
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) return json({ error: "Sign in required" }, 401)

  if (!GEMINI_API_KEY) return json({ error: "AI is not configured" }, 503)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: "Invalid JSON" }, 400)
  }

  const request = buildRequest(String(body.task ?? ""), body)
  if (!request) return json({ error: "Unknown task or invalid input" }, 400)

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_API_KEY },
        body: JSON.stringify({
          contents: [{ role: "user", parts: request.parts }],
          ...(request.json ? { generationConfig: { responseMimeType: "application/json" } } : {}),
        }),
      },
    )

    if (!response.ok) {
      // Log detail server-side only; never echo provider errors to clients.
      console.error("Gemini error", response.status, await response.text())
      return json({ error: "AI request failed" }, 502)
    }

    const result = await response.json()
    const text: string = (result?.candidates?.[0]?.content?.parts ?? [])
      .map((p: { text?: string }) => p.text ?? "")
      .join("")

    return json({ text })
  } catch (e) {
    console.error("ai-generate failure", e)
    return json({ error: "AI request failed" }, 502)
  }
})
