/** Reads the JSON error body from a failed Edge Function invoke. */
export async function functionErrorMessage(error, fallback) {
  const response = error?.context
  if (response && typeof response.json === 'function') {
    try {
      const body = await response.clone().json()
      if (body?.error) return String(body.error)
    } catch {
      // The function may have returned plain text.
    }
  }
  return error?.message || fallback
}
