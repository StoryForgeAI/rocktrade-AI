import Stripe from 'npm:stripe';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

import { corsHeaders } from '../_shared/cors.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2026-02-25.clover',
});

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const siteUrl = Deno.env.get('SITE_URL') ?? 'http://localhost:3000';

const priceMap = {
  starter: Deno.env.get('STRIPE_PRICE_STARTER') ?? '',
  pro: Deno.env.get('STRIPE_PRICE_PRO') ?? '',
  trader: Deno.env.get('STRIPE_PRICE_TRADER') ?? '',
  money_printer: Deno.env.get('STRIPE_PRICE_MONEY_PRINTER') ?? '',
  pack_50: Deno.env.get('STRIPE_PRICE_PACK_50') ?? '',
  pack_150: Deno.env.get('STRIPE_PRICE_PACK_150') ?? '',
  pack_500: Deno.env.get('STRIPE_PRICE_PACK_500') ?? '',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) {
      return new Response(JSON.stringify({ error: 'Missing auth header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
      global: { headers: { Authorization: authorization } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { productId, mode } = await request.json();
    const priceId = priceMap[productId as keyof typeof priceMap];

    if (!priceId) {
      return new Response(JSON.stringify({ error: 'Missing Stripe price for product' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const {
      data: existingSubscription,
    } = await supabase
      .from('subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', user.id)
      .maybeSingle();

    const session = await stripe.checkout.sessions.create({
      mode,
      customer: existingSubscription?.stripe_customer_id ?? undefined,
      customer_email: existingSubscription?.stripe_customer_id ? undefined : user.email ?? undefined,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${siteUrl}/dashboard?checkout=success`,
      cancel_url: `${siteUrl}/dashboard?checkout=canceled`,
      allow_promotion_codes: true,
      metadata: {
        user_id: user.id,
        product_id: productId,
        mode,
      },
      subscription_data:
        mode === 'subscription'
          ? {
              metadata: {
                user_id: user.id,
                product_id: productId,
              },
            }
          : undefined,
    });

    return new Response(
      JSON.stringify({ url: session.url }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
