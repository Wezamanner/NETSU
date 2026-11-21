// Creates a worker or administrator. Deploy with the Supabase CLI.
// The secret key stays in the function runtime and is never sent to the browser.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.86.0'

const phonePattern = /^\+2519\d{8}$/

type Body = {
  fullName?: string
  phone?: string
  password?: string
  role?: 'worker' | 'admin'
  areaId?: string | null
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const authorization = request.headers.get('Authorization') ?? ''

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
  })
  const { data: roleData, error: roleError } = await caller.rpc('auth_role')
  if (roleError || roleData !== 'admin') {
    return json({ error: 'Administrator access is required' }, 403)
  }

  const body = (await request.json()) as Body
  const fullName = (body.fullName ?? '').trim()
  const phone = (body.phone ?? '').trim()
  const password = body.password ?? ''
  const role = body.role
  if (!fullName || !phonePattern.test(phone) || password.length < 8) {
    return json({ error: 'Name, a +2519 phone number, and an 8 character password are required' }, 400)
  }
  if (role !== 'worker' && role !== 'admin') {
    return json({ error: 'Role must be worker or admin' }, 400)
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
  if (error || !data.user) {
    return json({ error: error?.message ?? 'User was not created' }, 400)
  }

  const { error: updateError } = await admin
    .from('profiles')
    .update({ role, full_name: fullName, area_id: body.areaId ?? null })
    .eq('id', data.user.id)
  if (updateError) {
    return json({ error: updateError.message }, 400)
  }

  return json({ id: data.user.id }, 200)
})

function json(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
