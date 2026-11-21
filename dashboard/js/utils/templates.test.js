import assert from 'node:assert/strict'
import test from 'node:test'
import { dedupKey, previewResidentMessage } from './templates.js'

test('formats resident day-before and same-day preview in Addis Ababa time', () => {
  const iso = '2026-11-22T05:00:00.000Z' // 8:00 AM EAT
  const dayBefore = previewResidentMessage({ type: 'day_before', locale: 'en', expectedStartIso: iso })
  const sameDay = previewResidentMessage({ type: 'same_day', locale: 'en', expectedStartIso: iso })
  assert.match(dayBefore, /8:00 AM/)
  assert.match(dayBefore, /scheduled for tomorrow/)
  assert.match(sameDay, /scheduled for today at 8:00 AM/)
})

test('builds deterministic deduplication keys', () => {
  const k = dedupKey({
    scheduleId: 's1',
    version: 2,
    type: 'day_before',
    recipientId: 'u1',
    channel: 'in_app',
  })
  assert.equal(k, 's1:v2:day_before:u1:in_app')
})
