'use client';

import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowRight,
  Bot,
  CheckCircle2,
  CreditCard,
  Gauge,
  LoaderCircle,
  LogOut,
  RefreshCcw,
  Settings2,
  Sparkles,
  UploadCloud,
  UserRound,
  Wallet,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

import { ThemeToggle } from '@/components/theme-toggle';
import { ANALYSIS_COST, CREDIT_PACKS, SUBSCRIPTIONS } from '@/lib/catalog';
import { supabase } from '@/lib/supabase';
import type {
  AnalysisRecord,
  DashboardData,
  TradeAnalysis,
  UserProfile,
} from '@/lib/types';
import { cn, formatDate } from '@/lib/utils';

type UploadState = {
  file: File | null;
  previewUrl: string | null;
};

export function DashboardShell() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [analysis, setAnalysis] = useState<TradeAnalysis | null>(null);
  const [upload, setUpload] = useState<UploadState>({ file: null, previewUrl: null });
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);

  useEffect(() => {
    void loadDashboard();
  }, []);

  useEffect(() => {
    const checkout = searchParams.get('checkout');
    if (checkout === 'success') {
      setMessage('Stripe checkout sikeres volt. Frissítsd az adatokat pár másodperc múlva, ha még nem látszik a változás.');
    }
    if (checkout === 'canceled') {
      setMessage('A Stripe checkout megszakadt, nem történt terhelés.');
    }
  }, [searchParams]);

  useEffect(() => {
    return () => {
      if (upload.previewUrl) {
        URL.revokeObjectURL(upload.previewUrl);
      }
    };
  }, [upload.previewUrl]);

  const latestSaved = dashboard?.analyses[0]?.result ?? null;
  const effectiveAnalysis = analysis ?? latestSaved;

  const canAnalyze = useMemo(() => {
    return Boolean(upload.file) && (dashboard?.profile.credits ?? 0) >= ANALYSIS_COST;
  }, [upload.file, dashboard?.profile.credits]);

  async function loadDashboard() {
    setLoading(true);
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session) {
        router.replace('/');
        return;
      }

      const userId = session.user.id;

      const [{ data: profile, error: profileError }, { data: subscription }, { data: analyses }] =
        await Promise.all([
          supabase.from('users').select('*').eq('id', userId).single(),
          supabase
            .from('subscriptions')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle(),
          supabase
            .from('analyses')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(8),
        ]);

      if (profileError) throw profileError;

      setDashboard({
        profile: profile as UserProfile,
        subscription: (subscription as DashboardData['subscription']) ?? null,
        analyses: ((analyses as AnalysisRecord[]) ?? []),
      });
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Nem sikerult betolteni a dashboardot.');
    } finally {
      setLoading(false);
    }
  }

  function setFile(file: File | null) {
    if (upload.previewUrl) {
      URL.revokeObjectURL(upload.previewUrl);
    }
    if (!file) {
      setUpload({ file: null, previewUrl: null });
      return;
    }
    setUpload({ file, previewUrl: URL.createObjectURL(file) });
  }

  async function handleAnalyze() {
    if (!upload.file || !dashboard) return;

    setBusy(true);
    setMessage(null);

    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        router.replace('/');
        return;
      }

      const storagePath = `${user.id}/${Date.now()}-${upload.file.name}`;

      const { error: uploadError } = await supabase.storage
        .from('uploads')
        .upload(storagePath, upload.file, {
          upsert: false,
          contentType: upload.file.type || 'image/png',
        });

      if (uploadError) throw uploadError;

      const { data, error } = await supabase.functions.invoke('analyze-trade-image', {
        body: { storagePath },
      });

      if (error) throw error;
      if (!data?.analysis) throw new Error('Nem jott vissza elemzesi adat.');

      setAnalysis(data.analysis as TradeAnalysis);
      setMessage('Elemzes kesz, az eredmeny el lett mentve es a kreditek frissultek.');
      await loadDashboard();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Az elemzes nem sikerult.');
    } finally {
      setBusy(false);
    }
  }

  async function handleCheckout(productId: string, mode: 'payment' | 'subscription') {
    setBusy(true);
    setMessage(null);
    try {
      const { data, error } = await supabase.functions.invoke('create-checkout-session', {
        body: { productId, mode },
      });
      if (error) throw error;
      if (!data?.url) throw new Error('A Stripe checkout URL hianyzik.');
      window.location.href = data.url as string;
    } catch (error) {
      setBusy(false);
      setMessage(error instanceof Error ? error.message : 'A checkout megnyitasa nem sikerult.');
    }
  }

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.replace('/');
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <LoaderCircle className="animate-spin text-orange-300" size={28} />
      </div>
    );
  }

  if (!dashboard) {
    return null;
  }

  return (
    <main className="min-h-screen px-6 py-8 md:px-10">
      <div className="mx-auto max-w-7xl">
        <header className="mb-8 flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="text-sm uppercase tracking-[0.18em] text-orange-200">
              SnapPrice dashboard
            </div>
            <h1 className="mt-2 text-3xl font-black text-white">
              {dashboard.profile.email}
            </h1>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => void loadDashboard()}
              className="inline-flex h-11 items-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 text-sm font-semibold text-white transition hover:border-orange-400/50"
            >
              <RefreshCcw size={16} />
              Refresh
            </button>
            <ThemeToggle />
            <button
              type="button"
              onClick={() => void handleSignOut()}
              className="inline-flex h-11 items-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 text-sm font-semibold text-white transition hover:border-orange-400/50"
            >
              <LogOut size={16} />
              Sign out
            </button>
          </div>
        </header>

        <section className="mb-6 grid gap-5 lg:grid-cols-[1.2fr_0.8fr]">
          <div className="rounded-[2rem] bg-gradient-to-br from-orange-500 via-orange-400 to-amber-200 p-6 text-black shadow-glow">
            <div className="flex flex-wrap gap-4">
              <MetricCard label="Credits" value={String(dashboard.profile.credits)} dark={false} />
              <MetricCard label="Plan" value={dashboard.profile.plan} dark={false} />
              <MetricCard
                label="Subscription"
                value={dashboard.subscription?.status ?? 'free'}
                dark={false}
              />
            </div>
            <p className="mt-6 max-w-2xl text-sm leading-6 text-black/75">
              Minden sikeres chart elemzes {ANALYSIS_COST} kreditet von le. A heti refill a
              Supabase oldalon fut, a Stripe fizetes pedig hosted checkouttal megy.
            </p>
          </div>

          <div className="glass p-6">
            <div className="flex items-center gap-3 text-white">
              <Bot size={18} className="text-orange-300" />
              <div className="font-bold">Runtime status</div>
            </div>
            <div className="mt-5 space-y-4 text-sm text-white/65">
              <StatusRow label="Auth" value="Supabase email + Google" />
              <StatusRow label="Uploads" value="Supabase Storage bucket: uploads" />
              <StatusRow label="AI" value="Supabase Edge Function to OpenAI" />
              <StatusRow label="Billing" value="Stripe Checkout + webhook sync" />
            </div>
          </div>
        </section>

        {message ? (
          <div className="mb-6 flex items-start gap-3 rounded-3xl border border-orange-400/30 bg-orange-500/10 px-5 py-4 text-sm text-orange-50">
            <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-orange-300" />
            <span>{message}</span>
          </div>
        ) : null}

        <section className="grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
          <div className="space-y-6">
            <Panel
              icon={<UploadCloud size={18} />}
              title="Upload & analysis"
              subtitle="Drag-and-drop vagy file picker alapjan megy a chart feltoltes."
            >
              <div
                onDragOver={(event) => {
                  event.preventDefault();
                  setDragging(true);
                }}
                onDragLeave={() => setDragging(false)}
                onDrop={(event) => {
                  event.preventDefault();
                  setDragging(false);
                  const dropped = event.dataTransfer.files?.[0];
                  if (dropped) setFile(dropped);
                }}
                className={cn(
                  'rounded-[1.75rem] border border-dashed p-6 transition',
                  dragging
                    ? 'border-orange-300 bg-orange-500/10'
                    : 'border-white/15 bg-black/20',
                )}
              >
                {upload.previewUrl ? (
                  <img
                    src={upload.previewUrl}
                    alt="Selected chart"
                    className="h-72 w-full rounded-[1.25rem] object-cover"
                  />
                ) : (
                  <div className="flex h-72 flex-col items-center justify-center rounded-[1.25rem] border border-white/10 bg-white/5 text-center text-white/55">
                    <UploadCloud size={28} className="mb-4 text-orange-300" />
                    <div className="font-semibold text-white">Drop a chart screenshot here</div>
                    <div className="mt-2 max-w-md text-sm leading-6">
                      BTC, forex, stock, TradingView, Binance, or broker screenshots all work.
                    </div>
                  </div>
                )}

                <div className="mt-5 flex flex-wrap gap-3">
                  <label className="inline-flex cursor-pointer items-center gap-2 rounded-2xl bg-orange-500 px-5 py-3 text-sm font-bold text-white transition hover:bg-orange-400">
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(event) => {
                        const nextFile = event.target.files?.[0] ?? null;
                        setFile(nextFile);
                      }}
                    />
                    Choose file
                  </label>

                  <button
                    type="button"
                    disabled={!canAnalyze || busy}
                    onClick={() => void handleAnalyze()}
                    className="inline-flex items-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm font-semibold text-white transition hover:border-orange-400/50 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {busy ? <LoaderCircle className="animate-spin" size={16} /> : <Sparkles size={16} />}
                    Analyze now
                  </button>
                </div>

                <div className="mt-4 text-sm text-white/55">
                  {upload.file ? upload.file.name : 'No file selected yet.'}
                </div>
              </div>
            </Panel>

            <Panel
              icon={<Gauge size={18} />}
              title="Latest result"
              subtitle="OpenAI altal strukturalt JSON-bol kirajzolt elemzes."
            >
              {effectiveAnalysis ? (
                <AnalysisView analysis={effectiveAnalysis} />
              ) : (
                <EmptyState text="Még nincs elemzés. Tölts fel egy chart screenshotot és futtasd le az első AI kört." />
              )}
            </Panel>

            <Panel
              icon={<Wallet size={18} />}
              title="Recent analyses"
              subtitle="A Supabase adatbazisban mentett legutobbi eredmenyek."
            >
              <div className="space-y-3">
                {dashboard.analyses.length ? (
                  dashboard.analyses.map((item) => (
                    <div
                      key={item.id}
                      className="rounded-3xl border border-white/10 bg-white/5 px-4 py-4"
                    >
                      <div className="flex flex-wrap items-center justify-between gap-3">
                        <div>
                          <div className="font-bold text-white">
                            {item.result.marketSentiment.toUpperCase()}
                          </div>
                          <div className="mt-1 text-sm text-white/55">
                            {item.result.entrySuggestion}
                          </div>
                        </div>
                        <div className="text-right text-sm text-white/55">
                          <div>{item.result.confidenceScore}% confidence</div>
                          <div>{formatDate(item.created_at)}</div>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <EmptyState text="A mentett analysis history itt fog megjelenni." />
                )}
              </div>
            </Panel>
          </div>

          <div className="space-y-6">
            <Panel
              icon={<CreditCard size={18} />}
              title="Billing"
              subtitle="Stripe hosted checkout a webes valtozathoz."
            >
              <div className="space-y-4">
                {SUBSCRIPTIONS.map((plan) => (
                  <CheckoutRow
                    key={plan.id}
                    title={plan.title}
                    price={plan.priceLabel}
                    description={plan.description}
                    badge={dashboard.profile.plan === plan.id ? 'Current' : undefined}
                    onClick={() => void handleCheckout(plan.id, plan.mode)}
                  />
                ))}
              </div>

              <div className="mt-6 border-t border-white/10 pt-6">
                <div className="mb-4 text-sm uppercase tracking-[0.18em] text-white/45">
                  Credit packs
                </div>
                <div className="space-y-4">
                  {CREDIT_PACKS.map((pack) => (
                    <CheckoutRow
                      key={pack.id}
                      title={pack.title}
                      price={pack.priceLabel}
                      description={pack.description}
                      onClick={() => void handleCheckout(pack.id, pack.mode)}
                    />
                  ))}
                </div>
              </div>
            </Panel>

            <Panel
              icon={<UserRound size={18} />}
              title="Account"
              subtitle="A Supabase users es subscriptions tablak adatai."
            >
              <InfoLine label="Email" value={dashboard.profile.email} />
              <InfoLine label="Credits" value={String(dashboard.profile.credits)} />
              <InfoLine label="Plan" value={dashboard.profile.plan} />
              <InfoLine label="Member since" value={formatDate(dashboard.profile.created_at)} />
              <InfoLine
                label="Current period end"
                value={formatDate(dashboard.subscription?.current_period_end)}
              />
            </Panel>

            <Panel
              icon={<Settings2 size={18} />}
              title="Settings"
              subtitle="A webes telepiteshez fontos futasi pontok."
            >
              <InfoLine label="Frontend" value="Next.js on Vercel" />
              <InfoLine label="Public envs" value="NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY" />
              <InfoLine label="Server secrets" value="Supabase Edge Functions + Stripe Dashboard" />
              <InfoLine label="Theme" value="Dark/light toggle a localStorage-ben" />
            </Panel>
          </div>
        </section>
      </div>
    </main>
  );
}

function Panel({
  icon,
  title,
  subtitle,
  children,
}: {
  icon: ReactNode;
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  return (
    <section className="glass p-6">
      <div className="mb-5 flex items-start gap-3">
        <div className="rounded-2xl bg-orange-500/15 p-3 text-orange-300">{icon}</div>
        <div>
          <h2 className="text-xl font-black text-white">{title}</h2>
          <p className="mt-1 text-sm leading-6 text-white/55">{subtitle}</p>
        </div>
      </div>
      {children}
    </section>
  );
}

function MetricCard({
  label,
  value,
  dark = true,
}: {
  label: string;
  value: string;
  dark?: boolean;
}) {
  return (
    <div
      className={cn(
        'rounded-3xl px-5 py-4',
        dark ? 'bg-white/5 text-white' : 'bg-black/10 text-black',
      )}
    >
      <div className={cn('text-xs uppercase tracking-[0.18em]', dark ? 'text-white/45' : 'text-black/50')}>
        {label}
      </div>
      <div className="mt-2 text-2xl font-black">{value}</div>
    </div>
  );
}

function StatusRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4">
      <span>{label}</span>
      <span className="rounded-full border border-white/10 px-3 py-1 text-xs text-white/85">
        {value}
      </span>
    </div>
  );
}

function CheckoutRow({
  title,
  price,
  description,
  onClick,
  badge,
}: {
  title: string;
  price: string;
  description: string;
  onClick: () => void;
  badge?: string;
}) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="font-bold text-white">{title}</h3>
            {badge ? (
              <span className="rounded-full border border-orange-400/30 bg-orange-500/10 px-3 py-1 text-xs font-semibold text-orange-200">
                {badge}
              </span>
            ) : null}
          </div>
          <div className="mt-1 text-white/80">{price}</div>
          <div className="mt-2 text-sm text-white/55">{description}</div>
        </div>
        <button
          type="button"
          onClick={onClick}
          className="inline-flex items-center gap-2 rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm font-semibold text-white transition hover:border-orange-400/50"
        >
          Checkout
          <ArrowRight size={16} />
        </button>
      </div>
    </div>
  );
}

function InfoLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-white/10 py-3 last:border-b-0">
      <div className="text-sm text-white/55">{label}</div>
      <div className="text-right text-sm font-semibold text-white">{value}</div>
    </div>
  );
}

function EmptyState({ text }: { text: string }) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 text-sm leading-6 text-white/55">
      {text}
    </div>
  );
}

function AnalysisView({ analysis }: { analysis: TradeAnalysis }) {
  const sentimentColor =
    analysis.marketSentiment === 'bullish'
      ? 'text-emerald-300 border-emerald-400/25 bg-emerald-500/10'
      : analysis.marketSentiment === 'bearish'
        ? 'text-rose-300 border-rose-400/25 bg-rose-500/10'
        : 'text-amber-300 border-amber-400/25 bg-amber-500/10';

  const riskColor =
    analysis.riskLevel === 'low'
      ? 'text-emerald-300 border-emerald-400/25 bg-emerald-500/10'
      : analysis.riskLevel === 'high'
        ? 'text-rose-300 border-rose-400/25 bg-rose-500/10'
        : 'text-amber-300 border-amber-400/25 bg-amber-500/10';

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={`${analysis.marketSentiment}-${analysis.confidenceScore}-${analysis.whenToBuy}`}
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -16 }}
        transition={{ duration: 0.25 }}
      >
        <div className="grid gap-3 md:grid-cols-3">
          <TagCard title="Sentiment" value={analysis.marketSentiment} className={sentimentColor} />
          <TagCard title="Risk" value={analysis.riskLevel} className={riskColor} />
          <TagCard title="Confidence" value={`${analysis.confidenceScore}%`} className="text-orange-200 border-orange-400/25 bg-orange-500/10" />
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <CopyBlock title="What is happening?" body={analysis.whatIsHappening} />
          <CopyBlock title="Why" body={analysis.reasoning} />
          <CopyBlock title="When to BUY" body={analysis.whenToBuy} />
          <CopyBlock title="When to SELL" body={analysis.whenToSell} />
        </div>

        <div className="mt-5 rounded-3xl border border-white/10 bg-black/20 p-5">
          <div className="mb-3 text-sm font-semibold text-white">Signals</div>
          <div className="flex flex-wrap gap-2">
            {[...analysis.keySignals, ...analysis.detectedIndicators].map((item) => (
              <span
                key={item}
                className="rounded-full border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-white/80"
              >
                {item}
              </span>
            ))}
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  );
}

function TagCard({
  title,
  value,
  className,
}: {
  title: string;
  value: string;
  className: string;
}) {
  return (
    <div className={cn('rounded-3xl border p-4', className)}>
      <div className="text-xs uppercase tracking-[0.18em] text-white/45">{title}</div>
      <div className="mt-2 text-2xl font-black capitalize">{value}</div>
    </div>
  );
}

function CopyBlock({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-5">
      <div className="text-sm font-semibold text-white">{title}</div>
      <p className="mt-3 text-sm leading-6 text-white/65">{body}</p>
    </div>
  );
}
