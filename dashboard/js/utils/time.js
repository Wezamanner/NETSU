const timeZone = 'Africa/Addis_Ababa'

export function formatAddisTime(value) {
  return new Intl.DateTimeFormat('en-US', {
    timeZone,
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(value))
}

export function formatAddisDate(value) {
  return new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(new Date(value))
}

/** Calendar date in Addis Ababa as YYYY-MM-DD. */
export function addisDateKey(value = new Date()) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(value))
}

/**
 * Convert an Addis Ababa wall date and time to a UTC ISO string.
 * Addis Ababa is UTC+3 all year. Returns null when the calendar date is invalid.
 */
export function addisLocalToUtc(date, time) {
  if (typeof date !== 'string' || typeof time !== 'string') return null
  const dateMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date)
  const timeMatch = /^(\d{2}):(\d{2})$/.exec(time)
  if (!dateMatch || !timeMatch) return null
  const year = Number(dateMatch[1])
  const month = Number(dateMatch[2])
  const day = Number(dateMatch[3])
  const hour = Number(timeMatch[1])
  const minute = Number(timeMatch[2])
  if (month < 1 || month > 12 || hour > 23 || minute > 59) return null
  const utc = new Date(Date.UTC(year, month - 1, day, hour - 3, minute, 0))
  if (Number.isNaN(utc.getTime())) return null
  if (addisDateKey(utc) !== date) return null
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(utc)
  const gotHour = parts.find((part) => part.type === 'hour')?.value
  const gotMinute = parts.find((part) => part.type === 'minute')?.value
  if (gotHour !== timeMatch[1] || gotMinute !== timeMatch[2]) return null
  return utc.toISOString()
}
