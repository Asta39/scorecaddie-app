// supabase/functions/send-reminder-notification/index.ts
// Runs on a cron schedule (every minute) to deliver tee time push notifications.
// Uses FCM HTTP v1 API (the legacy /fcm/send endpoint was shut down June 2024).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID')!
const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!

const supabase = createClient(supabaseUrl, supabaseServiceKey)

// ─── Get a short-lived OAuth2 access token from the Firebase service account ───
async function getFCMAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(serviceAccountJson)

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const signingInput = `${encode(header)}.${encode(payload)}`

  // Import the RSA private key
  const privateKey = serviceAccount.private_key
  const pemBody = privateKey.replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')
  const binaryKey = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8', binaryKey.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign']
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput)
  )

  const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')}`

  // Exchange JWT for an access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const tokenData = await tokenResponse.json()
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get FCM token: ${JSON.stringify(tokenData)}`)
  }

  return tokenData.access_token
}

// ─── Send a single FCM push notification via HTTP v1 API ───
async function sendFCMNotification(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  reminderId: string
): Promise<boolean> {
  const url = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        android: {
          notification: {
            icon: 'notification_icon',
            channel_id: 'tee_time_reminders',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        data: {
          type: 'tee_time_reminder',
          reminderId,
          click_action: 'OPEN_PROFILE',
        },
      },
    }),
  })

  if (!response.ok) {
    const err = await response.text()
    console.error(`FCM send failed for reminder ${reminderId}: ${err}`)
    return false
  }

  return true
}

// ─── Main handler ───
Deno.serve(async (_req) => {
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

    // Get a single access token to reuse across all sends this invocation
    const accessToken = await getFCMAccessToken()

    const results = []

    for (const reminder of reminders) {
      if (!reminder.fcm_token) {
        results.push({ id: reminder.id, status: 'skipped_no_fcm_token' })
        continue
      }

      const minutesBefore = reminder.notify_before_minutes
      const notificationBody = reminder.notes
        ? `Your round is in ${minutesBefore} minutes! Note: ${reminder.notes}`
        : `Your round is in ${minutesBefore} minutes. Get ready! ⛳`

      const sent = await sendFCMNotification(
        accessToken,
        reminder.fcm_token,
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
        results.push({ id: reminder.id, status: 'fcm_failed' })
      }
    }

    return new Response(JSON.stringify({ processed: results.length, results }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('send-reminder-notification error:', err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})