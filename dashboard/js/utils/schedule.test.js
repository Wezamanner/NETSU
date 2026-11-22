import assert from 'node:assert/strict'
import test from 'node:test'
import { addisLocalToUtc } from './time.js'
import { assignmentWarnings, blocksSave, rangesOverlap } from './schedule.js'

test('converts an Addis wall time to UTC', () => {
  assert.equal(addisLocalToUtc('2026-11-21', '18:00'), '2026-11-21T15:00:00.000Z')
  assert.equal(addisLocalToUtc('2026-11-22', '00:30'), '2026-11-21T21:30:00.000Z')
  assert.equal(addisLocalToUtc('2026-02-31', '10:00'), null)
})

test('warns on overlap and blocks a truck that is in maintenance', () => {
  const schedules = [{
    id: 'a',
    truck_id: 'truck-1',
    worker_ids: ['worker-1'],
    status: 'published',
    expected_start: '2026-11-22T12:00:00.000Z',
    expected_end: '2026-11-22T15:00:00.000Z',
  }]
  const overlap = assignmentWarnings({
    truck: { id: 'truck-1', maintenance: 'ok', availability: 'available' },
    workerIds: ['worker-1'],
    schedules,
    startIso: '2026-11-22T14:00:00.000Z',
    endIso: '2026-11-22T16:00:00.000Z',
  })
  assert.deepEqual(overlap, ['truck_overlap', 'worker_overlap'])
  assert.equal(blocksSave(overlap), false)

  const blocked = assignmentWarnings({
    truck: { id: 'truck-2', maintenance: 'in_maintenance', availability: 'available' },
    schedules: [],
    startIso: '2026-11-22T14:00:00.000Z',
  })
  assert.equal(blocksSave(blocked), true)
  assert.equal(rangesOverlap(0, 10, 10, 20), false)
})

test('reassigning a schedule does not clash with itself', () => {
  const schedules = [{
    id: 'a',
    truck_id: 'truck-1',
    worker_ids: ['worker-1'],
    status: 'assigned',
    expected_start: '2026-11-22T12:00:00.000Z',
    expected_end: null,
  }]
  const warnings = assignmentWarnings({
    truck: { id: 'truck-1', maintenance: 'ok', availability: 'assigned' },
    workerIds: ['worker-1'],
    schedules,
    startIso: '2026-11-22T12:00:00.000Z',
    endIso: null,
    ignoreId: 'a',
  })
  assert.deepEqual(warnings, [])
})
