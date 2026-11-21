import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.86.0/+esm'
import { supabaseConfig } from './config.js'

export function isConfigured() {
  return (
    supabaseConfig.url.startsWith('https://') &&
    supabaseConfig.publishableKey.startsWith('sb_publishable_')
  )
}

export const supabase = isConfigured()
  ? createClient(supabaseConfig.url, supabaseConfig.publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true },
    })
  : null
