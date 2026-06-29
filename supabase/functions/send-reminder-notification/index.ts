// supabase/functions/send-reminder-notification/index.ts
// Runs on a cron schedule (every minute) to deliver tee time push notifications.
// Uses OneSignal REST API for push notifications instead of FCM.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!

const supabase = createClient(supabaseUrl, supabaseServiceKey)

// ─── Send a single OneSignal push notification ───
async function sendOneSignalNotification(
  userId: string,
  title: string,
  body: string,
  reminderId: string
): Promise<boolean> {
  const url = `https://onesignal.com/api/v1/notifications`

  const payload = {
    app_id: ONESIGNAL_APP_ID,
    include_aliases: {
      external_id: [userId]
    },
    target_channel: "push",
    headings: { en: title },
    contents: { en: body },
    data: {
      type: 'tee_time_reminder',
      reminderId,
    }
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
    },
    body: JSON.stringify(payload)
  })

  if (!response.ok) {
    const err = await response.text()
    console.error(`OneSignal send failed for reminder ${reminderId}: ${err}`)
    return false
  }

  return true
}

// ─── Main handler ───
serve(async (_req) => {
  try {
    // Use the SQL function to get reminders that are due right now.
    // A reminder is due when: now >= (tee_time - notify_before_minutes).
    const { data: reminders, error } = await supabase.rpc('get_due_reminders')

    if (error) throw new Error(`Query error: ${error.message}`)

    if (!reminders || reminders.length === 0) {
      return new Response(JSON.stringify({ message: 'No reminders due' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const results = []

    for (const reminder of reminders) {
      if (!reminder.user_id) {
        results.push({ id: reminder.id, status: 'skipped_no_user_id' })
        continue
      }

      const minutesBefore = reminder.notify_before_minutes
      const notificationBody = reminder.notes
        ? `Your round is in ${minutesBefore} minutes! Note: ${reminder.notes}`
        : `Your round is in ${minutesBefore} minutes. Get ready! ⛳`

      const sent = await sendOneSignalNotification(
        reminder.user_id,
        '⛳ Tee Time Reminder',
        notificationBody,
        reminder.id.toString()
      )

      if (sent) {
        // Deactivate so it doesn't fire again next minute
        await supabase
          .from('tee_time_reminder')
          .update({ is_active: false })
          .eq('id', reminder.id)

        results.push({ id: reminder.id, status: 'sent' })
      } else {
        results.push({ id: reminder.id, status: 'onesignal_failed' })
      }
    }

    return new Response(JSON.stringify({ processed: results.length, results }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err: any) {
    console.error('send-reminder-notification error:', err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})