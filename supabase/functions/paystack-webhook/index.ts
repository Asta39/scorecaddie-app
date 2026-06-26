import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok')
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  try {
    // 1. Verify the webhook is genuinely from Paystack
    const signature = req.headers.get('x-paystack-signature')
    const bodyText = await req.text()
    
    // Convert secret key to crypto key
    const secretKey = Deno.env.get('PAYSTACK_SECRET_KEY') || ''
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secretKey),
      { name: 'HMAC', hash: 'SHA-512' },
      false,
      ['sign']
    )
    
    const expectedSigBuffer = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(bodyText))
    const expectedSignature = Array.from(new Uint8Array(expectedSigBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    if (signature !== expectedSignature) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 401 })
    }

    const event = JSON.parse(bodyText)

    // 2. Only handle successful charges
    if (event.event !== 'charge.success') {
      return new Response(JSON.stringify({ received: true }))
    }

    const { reference, amount, metadata, paid_at } = event.data
    const { entry_id, competition_id, player_id } = metadata

    // 3. Find the entry by reference
    const { data: entry, error: fetchError } = await supabase
      .from('competition_entries')
      .select('*, competitions(entry_fee_kes, club_id)')
      .eq('id', entry_id)
      .single()

    if (fetchError || !entry) {
      // Log unmatched payment — important for reconciliation
      await supabase.from('unmatched_payments').insert({
        paystack_reference: reference,
        amount_cents: amount,
        metadata,
        received_at: new Date().toISOString(),
      })
      return new Response(JSON.stringify({ received: true }))
    }

    // 4. Verify amount (amount from Paystack is in cents)
    const paidKes = amount / 100
    // @ts-ignore
    const expectedKes = entry.competitions?.entry_fee_kes || 0
    
    const isCorrectAmount = paidKes >= expectedKes

    // 5. Update entry — approved automatically, no admin needed
    await supabase
      .from('competition_entries')
      .update({
        payment_status: isCorrectAmount ? 'approved' : 'underpaid',
        paystack_reference: reference,
        mpesa_transaction_id: event.data.authorization?.receiver_bank_account_number ?? reference,
        mpesa_confirmed_amount: paidKes,
        mpesa_confirmed_at: paid_at,
        approved_at: isCorrectAmount ? new Date().toISOString() : null,
        approved_by: null,
        rejection_reason: !isCorrectAmount 
          ? `Underpayment — expected KES ${expectedKes}, received KES ${paidKes}`
          : null,
      })
      .eq('id', entry_id)

    // 6. Get player details for notification
    const { data: player } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', player_id)
      .single()

    // 7. Fire notifications via our own function
    await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/send-club-notification`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        trigger: isCorrectAmount ? 'payment_confirmed' : 'payment_underpaid',
        player_ids: [player_id], // Send only to the player
        club_id: entry.competitions?.club_id,
        competition_id,
        amount_paid: paidKes,
        player_name: player?.full_name,
      }),
    })

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (err: any) {
    console.error('Webhook error:', err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
