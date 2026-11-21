/** Office shell is administrators only. */
export function officeGate({ signedIn, role }) {
  if (!signedIn) return 'login'
  if (role !== 'admin') return 'blocked'
  return 'app'
}
