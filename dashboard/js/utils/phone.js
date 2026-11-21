const e164 = /^\+2519\d{8}$/

/** Accepts 09XXXXXXXX, 2519XXXXXXXX, or +2519XXXXXXXX. */
export function normalizeEthiopianMobile(input) {
  const compact = String(input ?? '').trim().replace(/[\s-]/g, '')
  let candidate = compact
  if (/^09\d{8}$/.test(compact)) candidate = `+251${compact.slice(1)}`
  else if (/^2519\d{8}$/.test(compact)) candidate = `+${compact}`
  return e164.test(candidate) ? candidate : null
}

export function syntheticEmail(phone) {
  return `${phone.replace('+', '')}@jimma-waste.app`
}
