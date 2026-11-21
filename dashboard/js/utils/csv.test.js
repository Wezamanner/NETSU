import assert from 'node:assert/strict'
import test from 'node:test'
import { buildCsv, escapeCsvCell } from './csv.js'

test('escapes commas, quotes, and newlines for CSV', () => {
  assert.equal(escapeCsvCell('Kebele 04'), 'Kebele 04')
  assert.equal(escapeCsvCell('Note, "urgent"'), '"Note, ""urgent"""')
  assert.equal(escapeCsvCell('line1\nline2'), '"line1\nline2"')
  assert.equal(escapeCsvCell(null), '')
})

test('builds RFC-4180 CSV with header and rows', () => {
  const out = buildCsv(['Area', 'Status'], [['01 — Kebele 01', 'completed']])
  assert.equal(out, 'Area,Status\r\n01 — Kebele 01,completed\r\n')
})
