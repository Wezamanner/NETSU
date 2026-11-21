import assert from 'node:assert/strict'
import test from 'node:test'
import { escapeHtml } from './escape.js'

test('escapes text that must not become markup', () => {
  assert.equal(escapeHtml(`<img src=x onerror=alert(1)>`), '&lt;img src=x onerror=alert(1)&gt;')
  assert.equal(escapeHtml(`A & B "C"`), 'A &amp; B &quot;C&quot;')
})
