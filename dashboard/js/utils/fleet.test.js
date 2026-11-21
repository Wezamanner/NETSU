import assert from 'node:assert/strict'
import test from 'node:test'
import { isValidPlate, normalizePlate, parseCapacity, parseStops } from './fleet.js'

test('normalizes a plate and accepts the seed format', () => {
  assert.equal(normalizePlate(' or-01-10001 '), 'OR-01-10001')
  assert.equal(isValidPlate('or-01-10001'), true)
  assert.equal(isValidPlate('0711000001'), false)
})

test('parses capacity and stops', () => {
  assert.deepEqual(parseCapacity(''), { ok: true, capacity: null })
  assert.deepEqual(parseCapacity('12.5'), { ok: true, capacity: 12.5 })
  assert.equal(parseCapacity('0').ok, false)
  assert.deepEqual(parseStops(' Market \n\n School gate '), {
    ok: true,
    stops: ['Market', 'School gate'],
  })
  assert.equal(parseStops('x'.repeat(121)).ok, false)
})
