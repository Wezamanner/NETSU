export function normalizePlate(value) {
  return String(value ?? '').trim().toUpperCase().replace(/\s+/g, '')
}

/** Accepts plates such as OR-01-10001. */
export function isValidPlate(value) {
  const plate = normalizePlate(value)
  return /^[A-Z]{1,4}-\d{1,4}-\d{1,6}$/.test(plate)
}

export function parseCapacity(value) {
  const text = String(value ?? '').trim()
  if (!text) return { ok: true, capacity: null }
  const capacity = Number(text)
  if (!Number.isFinite(capacity) || capacity <= 0 || capacity > 100000) {
    return { ok: false, capacity: null }
  }
  return { ok: true, capacity }
}

/** One collection stop per line. Empty lines are dropped. */
export function parseStops(text) {
  const stops = String(text ?? '')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
  if (stops.length > 40 || stops.some((stop) => stop.length > 120)) {
    return { ok: false, stops: [] }
  }
  return { ok: true, stops }
}
