import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { GoogleAuth } from 'npm:google-auth-library@9'

const packageName = 'com.aa.deinterviewprep'
const validProductIds = new Set([
  'de_interview_prep_lifetime_launch',
  'de_interview_prep_lifetime',
])

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Max-Age': '86400',
}

function json(body: Record<string, unknown>, status = 200) {
  return Response.json(body, { status, headers: corsHeaders })
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405)

  try {
    const authorization = request.headers.get('Authorization')
    if (!authorization?.startsWith('Bearer ')) {
      return json({ error: 'Authentication required.' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const serviceAccountValue = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON')
    if (!supabaseUrl || !serviceRoleKey || !serviceAccountValue) {
      throw new Error('Purchase verification secrets are not configured.')
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const token = authorization.slice('Bearer '.length)
    const { data: authData, error: authError } = await adminClient.auth.getUser(token)
    if (authError || !authData.user) {
      return json({ error: 'Invalid or expired session.' }, 401)
    }

    const body = await request.json().catch(() => ({}))
    const productId = typeof body.productId === 'string' ? body.productId : ''
    const purchaseToken =
      typeof body.purchaseToken === 'string' ? body.purchaseToken.trim() : ''
    const source = typeof body.source === 'string' ? body.source : ''
    if (source !== 'google_play') {
      return json({ error: 'Only Google Play purchases are supported.' }, 400)
    }
    if (!validProductIds.has(productId) || !purchaseToken) {
      return json({ error: 'Invalid product or purchase token.' }, 400)
    }

    let credentials
    try {
      credentials = JSON.parse(serviceAccountValue)
    } catch {
      throw new Error('The Google Play service account secret is invalid JSON.')
    }
    const googleAuth = new GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    })
    const authClient = await googleAuth.getClient()
    const accessTokenResult = await authClient.getAccessToken()
    const accessToken = typeof accessTokenResult === 'string'
      ? accessTokenResult
      : accessTokenResult?.token
    if (!accessToken) throw new Error('Could not authenticate with Google Play.')

    const verificationUrl =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}` +
      `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`
    const playResponse = await fetch(verificationUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    })
    const playPurchase = await playResponse.json().catch(() => ({}))
    if (!playResponse.ok) {
      console.error('Google Play verification failed:', playResponse.status, playPurchase)
      return json({ error: 'Google Play could not verify this purchase.' }, 400)
    }
    if (playPurchase.purchaseState !== 0) {
      return json({ error: 'The Google Play purchase is not completed.' }, 409)
    }
    if (playPurchase.productId && playPurchase.productId !== productId) {
      return json({ error: 'The verified product does not match the purchase.' }, 400)
    }

    const purchaseTokenHash = await sha256(purchaseToken)
    const { error: entitlementError } = await adminClient
      .schema('de_mobile_app')
      .from('user_entitlements')
      .upsert(
        {
          user_id: authData.user.id,
          is_pro: true,
          source: 'google_play',
          product_id: productId,
          order_id: playPurchase.orderId ?? null,
          purchase_token_hash: purchaseTokenHash,
          expires_at: null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      )
    if (entitlementError) {
      console.error('Entitlement upsert failed:', entitlementError)
      if (entitlementError.code === '23505') {
        return json({ error: 'This purchase belongs to another account.' }, 409)
      }
      throw entitlementError
    }

    return json({ isPro: true, productId })
  } catch (error) {
    console.error('Purchase verification failed:', error)
    return json({ error: 'Purchase verification failed. Please try Restore purchase.' }, 500)
  }
})
