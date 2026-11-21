import assert from 'node:assert/strict'
import test from 'node:test'
import { normalizeEthiopianMobile, syntheticEmail } from './phone.js'

test('normalizes Ethiopian mobile numbers', () => {
  assert.equal(normalizeEthiopianMobile('0911000001'), '+251911000001')
  assert.equal(normalizeEthiopianMobile('251911000001'), '+251911000001')
  assert.equal(normalizeEthiopianMobile('+251 911 000 001'), '+251911000001')
})

test('rejects numbers that are not 09 mobiles', () => {
  assert.equal(normalizeEthiopianMobile('0711000001'), null)
  assert.equal(normalizeEthiopianMobile('+251711000001'), null)
  assert.equal(normalizeEthiopianMobile('091100001'), null)
})

test('builds the synthetic email', () => {
  assert.equal(syntheticEmail('+251911000001'), '251911000001@jimma-waste.app')
})
