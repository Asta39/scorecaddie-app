import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

interface PaymentRequest {
  competition_id: string
  player_id: string
  membership_id: string
  playing_handicap: number
  mpesa_phone: string   // player's phone e.g. "0712345678"
  email: string         // player's email (Paystack requires this)
}

serve(async (req: Request) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  try {
    const payload: PaymentRequest = await req.json()

    // 1. Fetch competition details + verify player is eligible
    const { data: competition, error: compError } = await supabase
      .from('competitions')
      .select(`
        *,
        clubs(name)
      `)
      .eq('id', payload.competition_id)
      .single()

    if (compError || !competition) {
      return new Response(JSON.stringify({ error: 'Competition not found' }), { status: 404 })
    }

    // 2. Check player isn't already entered
    const { data: existingEntry } = await supabase
      .from('competition_entries')
      .select('id, payment_status')
      .eq('competition_id', payload.competition_id)
      .eq('player_id', payload.player_id)
      .single()

    if (existingEntry) {
      return new Response(JSON.stringify({ 
        error: 'Already registered',
        payment_status: existingEntry.payment_status 
      }), { status: 409 })
    }

    // 3. Create a PENDING entry first
    // (so we have a record even if the player abandons the payment)
    const { data: entry, error: entryError } = await supabase
      .from('competition_entries')
      .insert({
        competition_id: payload.competition_id,
        player_id: payload.player_id,
        membership_id: payload.membership_id,
        playing_handicap: payload.playing_handicap,
        payment_status: 'pending',
        mpesa_phone_number: payload.mpesa_phone,
      })
      .select()
      .single()

    if (entryError) {
      console.error('Failed to create entry:', entryError)
      return new Response(JSON.stringify({ error: 'Failed to create entry' }), { status: 500 })
    }

    // 4. Format phone for Paystack (254XXXXXXXXX format)
    const formattedPhone = payload.mpesa_phone
      .replace(/^0/, '254')      // 0712... → 254712...
      .replace(/^\+/, '')         // +254... → 254...
      .replace(/\s/g, '')         // remove spaces

    // 5. Initiate STK Push via Paystack
    const paystackResponse = await fetch('https://api.paystack.co/charge', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${Deno.env.get('PAYSTACK_SECRET_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: payload.email,
        amount: competition.entry_fee_kes * 100,  // Paystack uses cents
        currency: 'KES',
        mobile_money: {
          phone: formattedPhone,
          provider: 'mpesa',
        },
        metadata: {
          // These come back in the webhook — your matching keys
          competition_id: payload.competition_id,
          player_id: payload.player_id,
          entry_id: entry.id,
          club_name: competition.clubs.name,
          competition_name: competition.name,
        },
        // Unique reference per transaction — store this
        reference: `SC-${entry.id}-${Date.now()}`,
      }),
    })

    const paystackData = await paystackResponse.json()

    if (!paystackData.status) {
      // STK Push failed to initiate — clean up the pending entry
      await supabase
        .from('competition_entries')
        .update({ payment_status: 'stk_failed' })
        .eq('id', entry.id)

      return new Response(JSON.stringify({ 
        error: 'Payment initiation failed',
        detail: paystackData.message 
      }), { status: 502 })
    }

    // 6. Store the Paystack reference on the entry
    await supabase
      .from('competition_entries')
      .update({ 
        paystack_reference: paystackData.data.reference,
        stk_initiated_at: new Date().toISOString(),
      })
      .eq('id', entry.id)

    // 7. Return to Flutter app — player now sees "Check your phone"
    return new Response(JSON.stringify({
      success: true,
      entry_id: entry.id,
      reference: paystackData.data.reference,
      message: 'STK push sent — check your phone for the M-Pesa PIN prompt',
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (err: any) {
    console.error('Unexpected error:', err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
