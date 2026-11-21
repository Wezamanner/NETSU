// SMS provider abstraction (AGENTS.md Rule 8: interface + disabled stub only in MVP).

export type SmsResult = {
  ok: boolean
  providerMessageId?: string
  error?: string
  disabled?: boolean
}

export interface SmsProvider {
  send(to: string, message: string): Promise<SmsResult>
}

export class DisabledSmsProvider implements SmsProvider {
  async send(_to: string, _message: string): Promise<SmsResult> {
    return {
      ok: false,
      disabled: true,
      error: 'SMS channel is disabled in MVP.',
    }
  }
}
