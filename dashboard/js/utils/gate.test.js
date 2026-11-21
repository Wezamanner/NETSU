import assert from 'node:assert/strict'
import test from 'node:test'
import { officeGate } from './gate.js'

test('keeps anonymous visitors on the login page', () => {
  assert.equal(officeGate({ signedIn: false, role: null }), 'login')
})

test('blocks residents and workers', () => {
  assert.equal(officeGate({ signedIn: true, role: 'resident' }), 'blocked')
  assert.equal(officeGate({ signedIn: true, role: 'worker' }), 'blocked')
  assert.equal(officeGate({ signedIn: true, role: null }), 'blocked')
})

test('admits an administrator', () => {
  assert.equal(officeGate({ signedIn: true, role: 'admin' }), 'app')
})
