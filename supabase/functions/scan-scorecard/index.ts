import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { imageBase64, playerName, clubName } = await req.json()

    if (!imageBase64 || !playerName || !clubName) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: imageBase64, playerName, clubName' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY is not configured')
    }

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
  "holes": [
    {
      "hole": integer (1-18),
      "par": integer,
      "score": integer or null
    }
  ],
  "front_9_total": integer or null,
  "back_9_total": integer or null,
  "gross_total": integer or null,
  "warnings": ["String of warnings if any"]
}

Output must be raw JSON conforming to this schema.
`

    // Call Gemini REST API directly
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`
    
    // Check if the imageBase64 has a data URI prefix, if so, strip it
    let base64Data = imageBase64
    if (base64Data.includes(',')) {
      base64Data = base64Data.split(',')[1]
    }

    const payload = {
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: 'image/jpeg',
                data: base64Data
              }
            }
          ]
        }
      ],
      generationConfig: {
        responseMimeType: 'application/json'
      }
    }

    const res = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    })

    if (!res.ok) {
      const errText = await res.text()
      throw new Error(`Gemini API Error: ${res.status} ${errText}`)
    }

    const data = await res.json()
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text
    
    if (!text) {
      throw new Error('No text returned from Gemini API')
    }

    let parsedJson
    try {
      let cleanedJson = text.trim()
      if (cleanedJson.includes('```json')) {
        cleanedJson = cleanedJson.split('```json')[1].split('```')[0].trim()
      } else if (cleanedJson.includes('```')) {
        cleanedJson = cleanedJson.split('```')[1].split('```')[0].trim()
      }
      const startIndex = cleanedJson.indexOf('{')
      const endIndex = cleanedJson.lastIndexOf('}')
      if (startIndex !== -1 && endIndex !== -1) {
        cleanedJson = cleanedJson.substring(startIndex, endIndex + 1)
      }
      parsedJson = JSON.parse(cleanedJson)
    } catch (e) {
      throw new Error('Failed to parse Gemini response as JSON')
    }

    return new Response(
      JSON.stringify({ result: parsedJson }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('scan-scorecard error:', err)
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
