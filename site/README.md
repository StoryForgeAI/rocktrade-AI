# TradeScope Web

This is the Vercel-ready Next.js frontend for TradeScope.

## Folder role

- `app/`: routes and app shell
- `components/`: landing, auth, dashboard UI
- `lib/`: Supabase client, shared types, catalog, helpers

## 1. What goes where

### Vercel frontend env vars

Only these go into Vercel:

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
```

These are public browser values, so `NEXT_PUBLIC_` is correct here.

### Supabase Edge Function secrets

These do **not** go into Vercel. They go into Supabase:

```text
OPENAI_API_KEY
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
SITE_URL
STRIPE_PRICE_STARTER
STRIPE_PRICE_PRO
STRIPE_PRICE_TRADER
STRIPE_PRICE_MONEY_PRINTER
STRIPE_PRICE_PACK_50
STRIPE_PRICE_PACK_150
STRIPE_PRICE_PACK_500
```

## 2. Local development

Inside `site/`:

```bash
npm install
cp .env.example .env.local
```

Fill `.env.local` with:

```text
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Then run:

```bash
npm run dev
```

## 3. Vercel deployment

### Option A: Dashboard

1. Push this repository to GitHub.
2. Open Vercel.
3. Click `Add New -> Project`.
4. Import your GitHub repository.
5. In the project configuration screen:
   Set `Root Directory` to `site`
6. Vercel should detect `Next.js` automatically.
7. Before deploy, open `Environment Variables`.
8. Add:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
9. Click `Deploy`.

### Option B: CLI

Inside `site/`:

```bash
npm install -g vercel
vercel
```

For production:

```bash
vercel --prod
```

## 4. After the first Vercel deploy

Suppose Vercel gives you:

```text
https://tradescope-web.vercel.app
```

Then do these updates.

### Supabase Auth URL Configuration

Go to:

`Supabase -> Authentication -> URL Configuration`

Set:

- `Site URL` = `https://tradescope-web.vercel.app`

Add these redirect URLs:

- `https://tradescope-web.vercel.app`
- `https://tradescope-web.vercel.app/dashboard`

### Supabase Google provider

Go to:

`Supabase -> Authentication -> Providers -> Google`

You need Google OAuth client credentials from Google Cloud.

In Google Cloud, the OAuth redirect URI should be your Supabase callback URL:

```text
https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
```

That callback URL goes into Google Cloud, not your Vercel domain.

## 5. Supabase function secrets

Go to:

`Supabase -> Project Settings -> Edge Functions -> Secrets`

Add:

```text
OPENAI_API_KEY=sk-...
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...
SITE_URL=https://tradescope-web.vercel.app
STRIPE_PRICE_STARTER=price_...
STRIPE_PRICE_PRO=price_...
STRIPE_PRICE_TRADER=price_...
STRIPE_PRICE_MONEY_PRINTER=price_...
STRIPE_PRICE_PACK_50=price_...
STRIPE_PRICE_PACK_150=price_...
STRIPE_PRICE_PACK_500=price_...
```

`SITE_URL` must be your final frontend URL because Stripe checkout redirects back to:

- `/dashboard?checkout=success`
- `/dashboard?checkout=canceled`

## 6. Stripe webhook exact steps

1. Deploy the `stripe-webhook` Supabase function first.
2. In Stripe Dashboard go to:
   `Developers -> Webhooks`
3. Click `Add endpoint`
4. Endpoint URL:

```text
https://YOUR_SUPABASE_PROJECT.functions.supabase.co/stripe-webhook
```

5. Select these events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
6. Save
7. Open the created webhook
8. Click `Reveal` on the signing secret
9. Copy the `whsec_...` value
10. Paste it into Supabase Edge Function secrets as:

```text
STRIPE_WEBHOOK_SECRET=whsec_...
```

## 7. Stripe products and prices

Create recurring monthly prices:

- Starter: `1.99 USD / month`
- Pro: `5.99 USD / month`
- Trader: `12.99 USD / month`
- Money Printer: `19.99 USD / month`

Create one-time prices:

- 50 credits
- 150 credits
- 500 credits

For each created price, copy the `price_...` ID and map it to the matching Supabase secret.

## 8. Important architecture note

### Browser / Vercel

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### Supabase only

- OpenAI key
- Stripe secret key
- Stripe webhook secret
- Stripe price IDs
- site redirect base URL

The frontend never needs your OpenAI or Stripe secret keys.
