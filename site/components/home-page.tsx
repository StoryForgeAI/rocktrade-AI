'use client';

import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowRight,
  BadgeDollarSign,
  CandlestickChart,
  CreditCard,
  ShieldCheck,
  Sparkles,
} from 'lucide-react';

import { supabase } from '@/lib/supabase';

import { ThemeToggle } from '@/components/theme-toggle';
import { AuthCard } from '@/components/auth-card';
import type { ThemeMode } from '@/lib/types';

export function HomePage() {
  const [isReady, setIsReady] = useState(false);
  const [theme, setTheme] = useState<ThemeMode>('dark');

  useEffect(() => {
    const current =
      document.documentElement.dataset.theme === 'light' ? 'light' : 'dark';
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
        icon: Sparkles,
        title: 'OpenAI chart reading',
        body: 'Upload screenshots and get structured market sentiment, entries, exits, risk, and confidence.',
      },
      {
        icon: BadgeDollarSign,
        title: 'Credits and plans',
        body: '15 free starter credits, paid packs, and recurring subscriptions through Stripe Checkout.',
      },
      {
        icon: ShieldCheck,
        title: 'Supabase security',
        body: 'Auth, private uploads, saved analyses, and server-side secret handling stay cleanly separated.',
      },
    ],
    [],
  );

  if (!isReady) {
    return <div className="min-h-screen" />;
  }

  return (
    <main className="min-h-screen px-6 py-8 md:px-10">
      <div className="mx-auto flex max-w-7xl flex-col gap-8">
        <header className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-orange-500 to-amber-300 shadow-glow">
              <CandlestickChart className="text-white" size={22} />
            </div>
            <div>
              <div className="text-sm uppercase tracking-[0.2em] text-orange-200/80">
                SnapPrice
              </div>
              <div className="text-xs text-white/50">
                Trading AI for screenshot analysis
              </div>
            </div>
          </div>
          <ThemeToggle />
        </header>

        <section className="grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55 }}
            className="glass overflow-hidden p-8 md:p-10"
          >
            <div className="mb-10 inline-flex items-center gap-2 rounded-full border border-orange-400/30 bg-orange-500/10 px-4 py-2 text-sm text-orange-100">
              <Sparkles size={16} />
              Screenshot -> AI insight -> credits -> saved history
            </div>

            <h1 className="max-w-3xl text-4xl font-black leading-tight text-white md:text-6xl">
              Web dashboard for chart screenshots, subscriptions, and OpenAI-powered trade analysis.
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-7 text-white/70 md:text-lg">
              This version is built for the browser, so Stripe checkout, Google login,
              drag-and-drop upload, and Vercel deployment fit together cleanly.
            </p>

            <div className="mt-8 grid gap-4 md:grid-cols-3">
              <StatPill label="Default credits" value="15" />
              <StatPill label="Cost per analysis" value="10" />
              <StatPill label="Hosted on" value="Vercel + Supabase" />
            </div>

            <div className="mt-10 grid gap-4 md:grid-cols-3">
              {features.map((feature, index) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 16 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.12 + index * 0.08, duration: 0.4 }}
                  className="rounded-3xl border border-white/10 bg-white/5 p-5"
                >
                  <feature.icon className="mb-4 text-orange-300" size={18} />
                  <h2 className="font-bold text-white">{feature.title}</h2>
                  <p className="mt-2 text-sm leading-6 text-white/65">
                    {feature.body}
                  </p>
                </motion.div>
              ))}
            </div>

            <div className="mt-8 flex flex-wrap gap-3 text-sm text-white/60">
              <div className="rounded-full border border-white/10 px-4 py-2">
                Google Auth
              </div>
              <div className="rounded-full border border-white/10 px-4 py-2">
                Supabase Storage
              </div>
              <div className="rounded-full border border-white/10 px-4 py-2">
                Stripe Checkout
              </div>
              <div className="rounded-full border border-white/10 px-4 py-2">
                Structured JSON output
              </div>
            </div>
          </motion.div>

          <AnimatePresence mode="wait">
            <motion.div
              key={theme}
              initial={{ opacity: 0, x: 18 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -18 }}
              transition={{ duration: 0.35 }}
              className="glass p-6 md:p-8"
            >
              <AuthCard />
            </motion.div>
          </AnimatePresence>
        </section>

        <section className="grid gap-5 md:grid-cols-3">
          <FeatureStrip
            icon={<CreditCard size={18} />}
            title="Billing-ready"
            body="Subscriptions and one-time credit packs go through the same hosted checkout pipeline."
          />
          <FeatureStrip
            icon={<ShieldCheck size={18} />}
            title="Secrets off the frontend"
            body="The browser only gets public Supabase keys. OpenAI and Stripe secrets stay in Supabase Edge Functions."
          />
          <FeatureStrip
            icon={<ArrowRight size={18} />}
            title="Ready for Vercel"
            body="The app lives in a dedicated site folder so you can point Vercel at it without touching the existing Flutter files."
          />
        </section>
      </div>
    </main>
  );
}

function StatPill({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="text-xs uppercase tracking-[0.18em] text-white/45">{label}</div>
      <div className="mt-2 text-2xl font-black text-white">{value}</div>
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
    <div className="glass p-5">
      <div className="mb-3 text-orange-300">{icon}</div>
      <h3 className="font-bold text-white">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-white/65">{body}</p>
    </div>
  );
}
