import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

function buildDeepLink(trigger: string, clubId: string, competitionId?: string) {
  switch (trigger) {
    case 'new_competition':
    case 'entry_deadline_48h':
    case 'entry_deadline_2h':
    case 'payment_confirmed':
    case 'payment_underpaid':
      return `scorecaddie://clubs/${clubId}/competitions/${competitionId}`
    case 'starting_sheet':
      return `scorecaddie://clubs/${clubId}/competitions/${competitionId}/starting-sheet`
    case 'results':
      return `scorecaddie://clubs/${clubId}/competitions/${competitionId}/results`
    case 'new_post':
      return `scorecaddie://clubs/${clubId}/noticeboard`
    default:
      return `scorecaddie://clubs/${clubId}`
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok')
  }

  try {
    const payload = await req.json()
    const { trigger, club_id, competition_id, post_id, player_ids, amount_paid } = payload

    const notifications: Record<string, { title: string, body: string }> = {
      new_competition: {
        title: '🏆 New competition posted',
        body: 'Entries are now open — tap to register.',
      },
      entry_deadline_48h: {
        title: '⏰ Entries close in 48 hours',
        body: "Don't miss your spot — enter now.",
      },
      entry_deadline_2h: {
        title: '🚨 Entries close in 2 hours',
        body: 'Last chance to enter.',
      },
      starting_sheet: {
        title: '📋 Starting sheet is live',
        body: 'Your tee time has been assigned.',
      },
      payment_confirmed: {
        title: '✅ Payment confirmed',
        body: "You're in — entry approved.",
      },
      payment_underpaid: {
        title: '⚠️ Payment issue',
        body: `We received KES ${amount_paid ?? 0}, but the entry fee is higher. Please contact the club.`,
      },
      results: {
        title: '🎯 Results are in',
        body: 'See how you finished and your new handicap.',
      },
      new_post: {
        title: '📢 Notice from your club',
        body: 'Your club admin has posted an update.',
      },
    }

    const notificationConfig = notifications[trigger]
    if (!notificationConfig) {
      return new Response(JSON.stringify({ error: `Unknown trigger: ${trigger}` }), { status: 400 })
    }

    const { title, body } = notificationConfig

    // OneSignal API
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${Deno.env.get('ONESIGNAL_REST_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        app_id: Deno.env.get('ONESIGNAL_APP_ID'),
        // Target by Supabase user IDs
        include_aliases: {
          external_id: player_ids
        },
        target_channel: 'push',
        headings: { en: title },
        contents: { en: body },
        // Deep link data
        data: {
          trigger,
          club_id,
          competition_id: competition_id ?? '',
          post_id: post_id ?? '',
        },
        // Direct navigation URL
        url: buildDeepLink(trigger, club_id, competition_id),
        // Priority
        priority: trigger.includes('deadline') ? 10 : 5,
      }),
    })

    const result = await response.json()
    
    return new Response(JSON.stringify({ 
      success: true, 
      id: result.id, 
      recipients: result.recipients 
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (err: any) {
    console.error('Notification error:', err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
