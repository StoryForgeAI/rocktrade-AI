'use client';

import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowRight,
  CandlestickChart,
  CreditCard,
  ShieldCheck,
  Sparkles,
  UploadCloud,
} from 'lucide-react';

import { supabase } from '@/lib/supabase';

import { ThemeToggle } from '@/components/theme-toggle';
import { AuthCard } from '@/components/auth-card';
import type { ThemeMode } from '@/lib/types';

export function HomePage() {
  const [isReady, setIsReady] = useState(false);
  const [theme, setTheme] = useState<ThemeMode>('light');

  useEffect(() => {
    const current =
      document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
    setTheme(current);
    setIsReady(true);
  }, []);

  useEffect(() => {
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        window.location.href = '/dashboard';
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const features = useMemo(
    () => [
      {
        icon: UploadCloud,
        title: 'Upload any chart',
        body: 'Drag in a screenshot from TradingView, Binance, MetaTrader, or your broker dashboard.',
      },
      {
        icon: Sparkles,
        title: 'Get a focused trade readout',
        body: 'See bias, buy and sell timing, risk, confidence, and visual signals in a cleaner report.',
      },
      {
        icon: CreditCard,
        title: 'Manage plans with Stripe',
        body: 'Use simple subscriptions or one-time credit packs without changing your backend setup.',
      },
    ],
    [],
  );

  if (!isReady) return <div className="min-h-screen" />;

  return (
    <main className="min-h-screen px-4 py-5 md:px-8 md:py-8">
      <div className="mx-auto flex max-w-7xl flex-col gap-8">
        <header className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-orange-500 to-amber-300 text-white shadow-glow">
              <CandlestickChart size={22} />
            </div>
            <div>
              <div className="text-sm font-semibold uppercase tracking-[0.24em] text-orange-500">
                TradeScope
              </div>
              <div className="text-xs text-stone-500">
                AI trading analysis for screenshot-based workflows
              </div>
            </div>
          </div>
          <ThemeToggle />
        </header>

        <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55 }}
            className="rounded-[2rem] border border-orange-100 bg-white/85 p-7 shadow-[0_24px_80px_rgba(177,123,52,0.12)] backdrop-blur md:p-10"
          >
            <div className="inline-flex items-center gap-2 rounded-full border border-orange-200 bg-orange-50 px-4 py-2 text-sm font-medium text-stone-700">
              <Sparkles size={16} className="text-orange-500" />
              Screenshot {'->'} AI readout {'->'} clearer trade plan
            </div>

            <h1 className="mt-6 max-w-4xl text-4xl font-black leading-tight text-stone-900 md:text-6xl">
              A lighter web workspace for chart uploads, AI analysis, and subscription-driven access.
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-8 text-stone-600 md:text-lg">
              Built for fast review instead of clutter. Upload a chart, get a visual trade readout, and move between analysis, plans, profile, and dashboard tabs without digging through dense text.
            </p>

            <div className="mt-8 grid gap-4 md:grid-cols-3">
              <StatPill label="Starter credits" value="15" />
              <StatPill label="Cost per scan" value="10" />
              <StatPill label="Built for" value="Mobile + desktop" />
            </div>

            <div className="mt-10 grid gap-4 md:grid-cols-3">
              {features.map((feature, index) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 16 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.12 + index * 0.08, duration: 0.4 }}
                  className="rounded-[1.75rem] border border-stone-200 bg-[#fffaf4] p-5"
                >
                  <feature.icon className="mb-4 text-orange-500" size={18} />
                  <h2 className="font-bold text-stone-900">{feature.title}</h2>
                  <p className="mt-2 text-sm leading-6 text-stone-600">
                    {feature.body}
                  </p>
                </motion.div>
              ))}
            </div>

            <div className="mt-8 flex flex-wrap gap-3 text-sm text-stone-600">
              <Tag>Dashboard tab</Tag>
              <Tag>Analyze tab</Tag>
              <Tag>Plans tab</Tag>
              <Tag>Profile tab</Tag>
              <Tag>About tab</Tag>
            </div>
          </motion.div>

          <AnimatePresence mode="wait">
            <motion.div
              key={theme}
              initial={{ opacity: 0, x: 18 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -18 }}
              transition={{ duration: 0.35 }}
              className="rounded-[2rem] border border-orange-100 bg-white/88 p-6 shadow-[0_24px_80px_rgba(177,123,52,0.10)] backdrop-blur md:p-8"
            >
              <AuthCard />
            </motion.div>
          </AnimatePresence>
        </section>

        <section className="grid gap-5 md:grid-cols-3">
          <FeatureStrip
            icon={<ShieldCheck size={18} />}
            title="Secrets stay off the frontend"
            body="OpenAI and Stripe secrets remain in Supabase Edge Functions, so the web app keeps only public Supabase keys."
          />
          <FeatureStrip
            icon={<ArrowRight size={18} />}
            title="Designed for cleaner decisions"
            body="The product now opens analysis in a full-screen visual report instead of a dense block of dashboard text."
          />
          <FeatureStrip
            icon={<CreditCard size={18} />}
            title="Keeps your existing backend"
            body="No key renaming or backend reshaping is needed for this visual refresh."
          />
        </section>
      </div>
    </main>
  );
}

function StatPill({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[1.5rem] border border-stone-200 bg-[#fffaf4] p-4">
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{label}</div>
      <div className="mt-2 text-2xl font-black text-stone-900">{value}</div>
    </div>
  );
}

function FeatureStrip({
  icon,
  title,
  body,
}: {
  icon: ReactNode;
  title: string;
  body: string;
}) {
  return (
    <div className="rounded-[1.75rem] border border-stone-200 bg-white/80 p-5 shadow-[0_16px_48px_rgba(120,95,68,0.08)]">
      <div className="mb-3 text-orange-500">{icon}</div>
      <h3 className="font-bold text-stone-900">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-stone-600">{body}</p>
    </div>
  );
}

function Tag({ children }: { children: ReactNode }) {
  return (
    <div className="rounded-full border border-stone-200 bg-white px-4 py-2">
      {children}
    </div>
  );
}
