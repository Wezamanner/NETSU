// Creates a worker or administrator. Deploy with the Supabase CLI.
// The secret key stays in the function runtime and is never sent to the browser.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.86.0'

const phonePattern = /^\+2519\d{8}$/

type Body = {
  fullName?: string
  phone?: string
  password?: string
  role?: 'resident' | 'worker' | 'admin'
  areaId?: string | null
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ?? ''
  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY') ?? ''
  if (url.length === 0) {
    return json({ error: 'The function is missing its server keys' }, 500)
  }
  if (anonKey.length === 0) {
    return json({ error: 'The function is missing its server keys' }, 500)
  }
  if (secretKey.length === 0) {
    return json({ error: 'The function is missing its server keys' }, 500)
  }
  const authorization = request.headers.get('Authorization') ?? ''

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
  })
  const { data: roleData, error: roleError } = await caller.rpc('auth_role')
  if (roleError != null) {
    return json({ error: 'Administrator access is required' }, 403)
  }
  if (roleData !== 'admin') {
    return json({ error: 'Administrator access is required' }, 403)
  }

  const body = (await request.json()) as Body
  const fullName = (body.fullName ?? '').trim()
  const phone = (body.phone ?? '').trim()
  const password = body.password ?? ''
  const role = body.role
  if (fullName.length === 0) {
    return json({ error: 'Name, a +2519 phone number, and an 8 character password are required' }, 400)
  }
  if (!phonePattern.test(phone)) {
    return json({ error: 'Name, a +2519 phone number, and an 8 character password are required' }, 400)
  }
  if (password.length < 8) {
    return json({ error: 'Name, a +2519 phone number, and an 8 character password are required' }, 400)
  }
  if (role !== 'resident' && role !== 'worker' && role !== 'admin') {
    return json({ error: 'Role must be resident, worker, or admin' }, 400)
  }

  const admin = createClient(url, secretKey)
  const email = `${phone.replace('+', '')}@jimma-waste.app`
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      phone,
      area_id: body.areaId ?? null,
      preferred_language: 'en',
    },
  })
  if (error != null) {
    return json({ error: error.message }, 400)
  }
  if (data.user == null) {
    return json({ error: 'User was not created' }, 400)
  }

  // Signup stores a resident. Worker and administrator accounts are appointed after that.
  if (role === 'worker' || role === 'admin') {
    const { error: updateError } = await caller.rpc('appoint_staff', {
      target_id: data.user.id,
      next_role: role,
      next_area: body.areaId ?? null,
      next_name: fullName,
    })
    if (updateError) {
      return json({ error: updateError.message }, 400)
    }
  }

  return json({ id: data.user.id }, 200)
})

function json(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  })
}
