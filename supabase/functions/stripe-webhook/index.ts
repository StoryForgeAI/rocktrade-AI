import Stripe from 'npm:stripe';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

import { corsHeaders } from '../_shared/cors.ts';
import { creditPackAmounts } from '../_shared/catalog.ts';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2026-02-25.clover',
});

const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

function planFromPriceId(priceId?: string | null): string {
  const map = {
    [Deno.env.get('STRIPE_PRICE_STARTER') ?? '']: 'starter',
    [Deno.env.get('STRIPE_PRICE_PRO') ?? '']: 'pro',
    [Deno.env.get('STRIPE_PRICE_TRADER') ?? '']: 'trader',
    [Deno.env.get('STRIPE_PRICE_MONEY_PRINTER') ?? '']: 'money_printer',
  };

  return map[priceId ?? ''] ?? 'free';
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const signature = request.headers.get('stripe-signature');
    const body = await request.text();

    if (!signature) {
      return new Response('Missing stripe-signature', { status: 400, headers: corsHeaders });
    }

    const event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.user_id;
        const productId = session.metadata?.product_id;

        if (userId && session.mode === 'payment' && productId) {
          const credits = creditPackAmounts[productId] ?? 0;
          if (credits > 0) {
            await supabase.rpc('apply_credit_pack', {
              p_user_id: userId,
              p_amount: credits,
              p_reason: `stripe_pack:${productId}`,
            });
          }
        }
        break;
      }
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.user_id;
        const priceId = subscription.items.data[0]?.price.id;
        const plan = planFromPriceId(priceId);

        if (userId) {
          await supabase.rpc('upsert_subscription_from_stripe', {
            p_user_id: userId,
            p_customer_id: subscription.customer as string,
            p_subscription_id: subscription.id,
            p_plan: plan,
            p_status: subscription.status === 'active' ? 'active' : subscription.status,
            p_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            p_last_credit_refill_at: new Date().toISOString(),
          });
        }
        break;
      }
      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.user_id;
        if (userId) {
          await supabase.rpc('upsert_subscription_from_stripe', {
            p_user_id: userId,
            p_customer_id: subscription.customer as string,
            p_subscription_id: subscription.id,
            p_plan: 'free',
            p_status: 'canceled',
            p_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            p_last_credit_refill_at: null,
          });
        }
        break;
      }
      case 'invoice.paid': {
        const invoice = event.data.object as Stripe.Invoice;
        if (invoice.subscription && invoice.customer) {
          const subscription = await stripe.subscriptions.retrieve(invoice.subscription as string);
          const userId = subscription.metadata.user_id;
          const priceId = subscription.items.data[0]?.price.id;
          const plan = planFromPriceId(priceId);

          if (userId) {
            await supabase.rpc('upsert_subscription_from_stripe', {
              p_user_id: userId,
              p_customer_id: invoice.customer as string,
              p_subscription_id: subscription.id,
              p_plan: plan,
              p_status: 'active',
              p_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
              p_last_credit_refill_at: null,
            });
          }
        }
        break;
      }
      default:
        break;
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
