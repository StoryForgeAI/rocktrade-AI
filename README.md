# SnapPrice

This repository now has two layers:

- `supabase/`: database migration and Edge Functions for OpenAI, Stripe, storage, and credit logic
- `site/`: Next.js web frontend intended for Vercel deployment

The original Flutter files are still present, but the active web product is the `site/` app.

## What the web app does

- Email/password and Google login through Supabase Auth
- Screenshot upload to Supabase Storage
- OpenAI chart analysis through `analyze-trade-image`
- Saved analyses and credit deduction
- Stripe Checkout for subscriptions and one-time credit packs
- Account and billing dashboard

## Frontend env vars

The browser only needs public Supabase values.

Use these in `site/.env.local` for local development or in Vercel Environment Variables:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Do not put `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, or `STRIPE_WEBHOOK_SECRET` in Vercel frontend env vars.

## Local web run

From `site/`:

```bash
npm install
npm run dev
```

## Supabase setup

1. Create a Supabase project.
2. Run the SQL from `supabase/migrations/20260425_snapprice_core.sql`.
3. Deploy the functions:

```bash
supabase functions deploy analyze-trade-image
supabase functions deploy create-checkout-session
supabase functions deploy stripe-webhook
supabase functions deploy refill-weekly-credits
```

4. Add Edge Function secrets:

```bash
supabase secrets set OPENAI_API_KEY=...
supabase secrets set STRIPE_SECRET_KEY=...
supabase secrets set STRIPE_WEBHOOK_SECRET=...
supabase secrets set SITE_URL=https://YOUR_VERCEL_DOMAIN
supabase secrets set STRIPE_PRICE_STARTER=price_...
supabase secrets set STRIPE_PRICE_PRO=price_...
supabase secrets set STRIPE_PRICE_TRADER=price_...
supabase secrets set STRIPE_PRICE_MONEY_PRINTER=price_...
supabase secrets set STRIPE_PRICE_PACK_50=price_...
supabase secrets set STRIPE_PRICE_PACK_150=price_...
supabase secrets set STRIPE_PRICE_PACK_500=price_...
```

5. In `Authentication -> Providers`, enable Email and Google.
6. In `Authentication -> URL Configuration`, add your Vercel production URL as `Site URL` and also add the allowed redirect URLs you actually use.
7. Keep the `uploads` bucket private.
8. Schedule `refill-weekly-credits` once per day or once per week.

## Stripe setup

Create monthly recurring prices:

- Starter: `$1.99/month`
- Pro: `$5.99/month`
- Trader: `$12.99/month`
- Money Printer: `$19.99/month`

Create one-time prices:

- `pack_50`
- `pack_150`
- `pack_500`

Create a webhook endpoint:

```text
https://YOUR_SUPABASE_PROJECT.functions.supabase.co/stripe-webhook
```

Subscribe it to:

- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`

## Vercel

Deploy the `site/` folder as a Next.js project. Full click-by-click notes are in:

- `site/README.md`

## OpenAI docs used

- [Models](https://developers.openai.com/api/docs/models)
- [Responses API](https://platform.openai.com/docs/api-reference/responses/create?api-mode=responses)
- [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs?lang=javascript)

## Infra docs used

- [Next.js on Vercel](https://vercel.com/docs/frameworks/nextjs)
- [Vercel environment variables](https://vercel.com/docs/environment-variables)
- [Vercel project settings](https://vercel.com/docs/project-configuration/project-settings)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase Edge Function secrets](https://supabase.com/docs/guides/functions/secrets)
- [Supabase Google login](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Stripe Checkout Session create](https://docs.stripe.com/api/checkout/sessions/create)
- [Stripe subscriptions guide](https://docs.stripe.com/payments/subscriptions)
