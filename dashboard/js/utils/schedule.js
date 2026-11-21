/** Used when a schedule has no expected end. TODO(decision): confirm the planning window. */
export const defaultWindowMs = 4 * 60 * 60 * 1000

export function rangeEnd(startMs, endIso) {
  if (endIso) {
    const end = new Date(endIso).getTime()
    if (!Number.isNaN(end)) return end
  }
  return startMs + defaultWindowMs
}

export function rangesOverlap(aStart, aEnd, bStart, bEnd) {
  return aStart < bEnd && bStart < aEnd
}

/**
 * Warn when a truck or worker is already booked. Maintenance is a hard block.
 * Cancelled schedules do not count as bookings.
 */
export function assignmentWarnings({ truck, workerIds = [], schedules = [], startIso, endIso, ignoreId }) {
  const start = new Date(startIso).getTime()
  if (Number.isNaN(start)) return []
  const end = rangeEnd(start, endIso)
  const warnings = []
  if (truck?.maintenance === 'in_maintenance') warnings.push('maintenance')
  else if (truck?.availability === 'unavailable') warnings.push('unavailable')

  const selected = new Set(workerIds)
  for (const item of schedules) {
    if (item.id === ignoreId || item.status === 'cancelled') continue
    const otherStart = new Date(item.expected_start).getTime()
    if (Number.isNaN(otherStart)) continue
    const otherEnd = rangeEnd(otherStart, item.expected_end)
    if (!rangesOverlap(start, end, otherStart, otherEnd)) continue
    if (truck && item.truck_id === truck.id && !warnings.includes('truck_overlap')) {
      warnings.push('truck_overlap')
    }
    const ids = item.worker_ids ?? []
    if (ids.some((id) => selected.has(id)) && !warnings.includes('worker_overlap')) {
      warnings.push('worker_overlap')
    }
  }
  return warnings
}

export function blocksSave(warnings) {
  return warnings.includes('maintenance')
}
