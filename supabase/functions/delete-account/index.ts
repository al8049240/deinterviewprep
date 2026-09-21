import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return Response.json(
      { error: 'Method not allowed.' },
      { status: 405, headers: corsHeaders },
    )
  }

  try {
    const body = await request.json().catch(() => ({}))
    if (body.confirmation !== 'DELETE_MY_ACCOUNT') {
      return Response.json(
        { error: 'Account deletion confirmation is missing.' },
        { status: 400, headers: corsHeaders },
      )
    }

    const authorization = request.headers.get('Authorization')
    if (!authorization?.startsWith('Bearer ')) {
      return Response.json(
        { error: 'Authentication required.' },
        { status: 401, headers: corsHeaders },
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      throw new Error('Required Supabase environment variables are missing.')
    }

    const token = authorization.slice('Bearer '.length)
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { data, error: userError } = await authClient.auth.getUser(token)
    if (userError || !data.user) {
      return Response.json(
        { error: 'Invalid or expired session.' },
        { status: 401, headers: corsHeaders },
      )
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      data.user.id,
    )
    if (deleteError) throw deleteError

    return Response.json(
      { deleted: true },
      { status: 200, headers: corsHeaders },
    )
  } catch (error) {
    console.error('Account deletion failed:', error)
    return Response.json(
      { error: 'Account deletion failed.' },
      { status: 500, headers: corsHeaders },
    )
  }
})
