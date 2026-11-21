// Processes due pending notifications on a 5-minute pg_cron schedule.
// Re-validates schedule status, schedule version, recipient active state,
// preferences, and quiet hours before sending. Never deletes records.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.86.0'
import { DisabledSmsProvider, type SmsProvider } from './sms_provider.ts'

const ESSENTIAL_TYPES = new Set(['delay', 'cancellation', 'reschedule'])
const DEFAULT_BACKOFF_MINUTES = [5, 15, 60]
const DEFAULT_MAX_RETRIES = 3

const smsProvider: SmsProvider = new DisabledSmsProvider()

type NotificationRow = {
  id: string
  recipient_id: string
  schedule_id: string | null
  type: string
  channel: 'in_app' | 'push' | 'sms'
  title: string
  message: string
  scheduled_send_at: string
  retry_count: number
  schedule_version: number | null
}

function addisHourMinute(date = new Date()): { hour: number; minute: number } {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Africa/Addis_Ababa',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date)
  const hour = Number(parts.find((p) => p.type === 'hour')?.value ?? '12')
  const minute = Number(parts.find((p) => p.type === 'minute')?.value ?? '0')
  return { hour, minute }
}

function isQuietHours(quiet: { start?: string; end?: string } | null, now = new Date()): boolean {
  const startStr = quiet?.start ?? '21:00'
  const endStr = quiet?.end ?? '06:00'
  const [sh, sm] = startStr.split(':').map(Number)
  const [eh, em] = endStr.split(':').map(Number)
  if ([sh, sm, eh, em].some(Number.isNaN)) return false
  const cur = addisHourMinute(now)
  const curMins = cur.hour * 60 + cur.minute
  const startMins = sh * 60 + sm
  const endMins = eh * 60 + em
  if (startMins > endMins) {
    return curMins >= startMins || curMins < endMins
  }
  return curMins >= startMins && curMins < endMins
}

function nextRetryTime(retryCount: number, backoffMinutes: number[]): string {
  const idx = Math.min(retryCount, backoffMinutes.length - 1)
  const delayMs = (backoffMinutes[idx] ?? 15) * 60 * 1000
  return new Date(Date.now() + delayMs).toISOString()
}

async function sendFcm(tokens: string[], title: string, body: string): Promise<{ ok: boolean; id?: string }> {
  const fcmUrl = Deno.env.get('FCM_ENDPOINT') ?? ''
  const fcmBearer = Deno.env.get('FCM_ACCESS_TOKEN') ?? ''
  if (!fcmUrl || !fcmBearer || tokens.length === 0) {
    return { ok: false }
  }
  for (const token of tokens) {
    const res = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${fcmBearer}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: { token, notification: { title, body } },
      }),
    })
    if (res.ok) {
      const payload = await res.json().catch(() => ({}))
      return { ok: true, id: typeof payload?.name === 'string' ? payload.name : undefined }
    }
  }
  return { ok: false }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const cronSecret = Deno.env.get('CRON_SECRET') ?? ''
  if (cronSecret && request.headers.get('x-cron-secret') !== cronSecret) {
    return json({ error: 'Unauthorized' }, 401)
  }

  const admin = createClient(url, secretKey)

  const { data: settingsRows } = await admin.from('app_settings').select('key, value')
  const settings = new Map((settingsRows ?? []).map((r: { key: string; value: unknown }) => [r.key, r.value]))
  const quiet = (settings.get('quiet_hours') as { start?: string; end?: string } | null) ?? null
  const maxRetries = Number(settings.get('max_retries') ?? DEFAULT_MAX_RETRIES)
  const backoff = Array.isArray(settings.get('retry_backoff_minutes'))
    ? (settings.get('retry_backoff_minutes') as number[])
    : DEFAULT_BACKOFF_MINUTES

  const { data: due, error: claimError } = await admin.rpc('claim_due_notifications', { batch_size: 50 })
  if (claimError) {
    return json({ error: claimError.message }, 500)
  }

  const stats = { processed: 0, sent: 0, cancelled: 0, retried: 0, failed: 0, deferred: 0 }

  for (const job of (due ?? []) as NotificationRow[]) {
    stats.processed += 1
    const isEssential = ESSENTIAL_TYPES.has(job.type)

    // 1. Validate recipient is active and still allows this channel/type.
    const { data: recipient } = await admin
      .from('profiles')
      .select('id, phone, active, notification_prefs, fcm_tokens')
      .eq('id', job.recipient_id)
      .maybeSingle()

    if (!recipient || recipient.active !== true) {
      await markCancelled(admin, job.id)
      stats.cancelled += 1
      continue
    }

    const prefs = (recipient.notification_prefs ?? {}) as Record<string, boolean>
    if (!isEssential && (prefs[job.channel] === false || prefs[job.type] === false)) {
      await markCancelled(admin, job.id)
      stats.cancelled += 1
      continue
    }

    // 2. Re-validate schedule state, version, and collection time before sending.
    if (job.schedule_id) {
      const { data: schedule } = await admin
        .from('collection_schedules')
        .select('id, status, version, expected_start')
        .eq('id', job.schedule_id)
        .maybeSingle()

      const staleVersion = job.schedule_version != null && schedule?.version !== job.schedule_version
      const inactiveSchedule = !schedule || schedule.status === 'draft' ||
        (schedule.status === 'cancelled' && job.type !== 'cancellation')
      const reminderPassed = (job.type === 'day_before' || job.type === 'same_day') &&
        schedule != null && new Date(schedule.expected_start).getTime() <= Date.now()

      if (staleVersion || inactiveSchedule || reminderPassed) {
        await markCancelled(admin, job.id)
        stats.cancelled += 1
        continue
      }
    }

    // 3. Respect quiet hours for non-essential reminders.
    if (!isEssential && isQuietHours(quiet)) {
      const deferTo = new Date(Date.now() + 30 * 60 * 1000).toISOString()
      await admin.from('notifications').update({ scheduled_send_at: deferTo }).eq('id', job.id)
      stats.deferred += 1
      continue
    }

    // 4. Deliver per channel.
    if (job.channel === 'in_app') {
      await admin.from('notifications').update({
        delivery_status: 'sent',
        sent_at: new Date().toISOString(),
      }).eq('id', job.id)
      stats.sent += 1
      continue
    }

    if (job.channel === 'sms') {
      const res = await smsProvider.send(recipient.phone, job.message)
      if (res.disabled) {
        await markCancelled(admin, job.id)
        stats.cancelled += 1
        continue
      }
      if (res.ok) {
        await admin.from('notifications').update({
          delivery_status: 'sent',
          sent_at: new Date().toISOString(),
          provider_message_id: res.providerMessageId ?? null,
        }).eq('id', job.id)
        stats.sent += 1
        continue
      }
    }

    if (job.channel === 'push') {
      const tokens = Array.isArray(recipient.fcm_tokens) ? (recipient.fcm_tokens as string[]) : []
      const res = await sendFcm(tokens, job.title, job.message)
      if (res.ok) {
        await admin.from('notifications').update({
          delivery_status: 'sent',
          sent_at: new Date().toISOString(),
          provider_message_id: res.id ?? null,
        }).eq('id', job.id)
        stats.sent += 1
        continue
      }
    }

    // 5. Retry policy (never delete the record).
    const nextCount = (job.retry_count ?? 0) + 1
    if (nextCount >= maxRetries) {
      await admin.from('notifications').update({
        delivery_status: 'failed',
        retry_count: nextCount,
      }).eq('id', job.id)
      stats.failed += 1
    } else {
      await admin.from('notifications').update({
        retry_count: nextCount,
        scheduled_send_at: nextRetryTime(job.retry_count ?? 0, backoff),
      }).eq('id', job.id)
      stats.retried += 1
    }
  }

  return json(stats, 200)
})

async function markCancelled(admin: ReturnType<typeof createClient>, id: string) {
  await admin.from('notifications').update({ delivery_status: 'cancelled' }).eq('id', id)
}

function json(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
