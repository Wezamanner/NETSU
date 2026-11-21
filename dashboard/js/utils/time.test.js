import assert from 'node:assert/strict'
import test from 'node:test'
import { addisDateKey, formatAddisTime } from './time.js'

test('converts a UTC instant to Addis Ababa wall time', () => {
  assert.equal(formatAddisTime('2026-11-21T15:00:00Z'), '6:00 PM')
  assert.equal(addisDateKey('2026-11-21T21:30:00Z'), '2026-11-22')
})
