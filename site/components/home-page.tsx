'use client';

import { motion } from 'framer-motion';
import {
  ArrowRight,
  CandlestickChart,
  ChartNoAxesCombined,
  Play,
  ShieldCheck,
  Sparkles,
} from 'lucide-react';
import Link from 'next/link';

import { ThemeToggle } from '@/components/theme-toggle';

export function HomePage() {
  return (
    <main className="min-h-screen overflow-hidden px-4 py-5 md:px-8 md:py-8">
      <div className="mx-auto max-w-7xl">
        <header className="mb-6 flex items-center justify-between">
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

        <section className="relative overflow-hidden rounded-[2.5rem] border border-orange-100 bg-white/86 px-6 py-8 shadow-[0_32px_120px_rgba(177,123,52,0.14)] backdrop-blur md:px-10 md:py-12">
          <motion.div
            initial={{ opacity: 0, scale: 0.92 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6 }}
            className="pointer-events-none absolute -right-10 top-0 h-64 w-64 rounded-full bg-orange-200/40 blur-3xl"
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.92 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8 }}
            className="pointer-events-none absolute bottom-0 left-0 h-72 w-72 rounded-full bg-amber-100/40 blur-3xl"
          />

          <div className="relative grid gap-8 xl:grid-cols-[1.04fr_0.96fr]">
            <div>
              <motion.div
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.45 }}
                className="inline-flex items-center gap-2 rounded-full border border-orange-200 bg-orange-50 px-4 py-2 text-sm font-medium text-stone-700"
              >
                <Sparkles size={16} className="text-orange-500" />
                Screenshot {'->'} AI trade plan {'->'} action
              </motion.div>

              <motion.h1
                initial={{ opacity: 0, y: 28 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.55, delay: 0.05 }}
                className="mt-6 max-w-4xl text-5xl font-black leading-[1.02] text-stone-900 md:text-7xl"
              >
                Turn chart screenshots into a sharp, visual trading readout.
              </motion.h1>

              <motion.p
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.55, delay: 0.12 }}
                className="mt-6 max-w-2xl text-base leading-8 text-stone-600 md:text-lg"
              >
                TradeScope reads chart screenshots, extracts momentum and risk context, and opens the result in a full-screen analysis view built for quick understanding.
              </motion.p>

              <motion.div
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.55, delay: 0.18 }}
                className="mt-8 flex flex-wrap gap-3"
              >
                <Link
                  href="/auth"
                  className="inline-flex items-center gap-2 rounded-2xl bg-stone-900 px-6 py-4 text-sm font-semibold text-white transition hover:bg-stone-800"
                >
                  Start Now
                  <ArrowRight size={18} />
                </Link>
                <a
                  href="#overview"
                  className="inline-flex items-center gap-2 rounded-2xl border border-stone-200 bg-white px-6 py-4 text-sm font-semibold text-stone-700 transition hover:border-orange-300 hover:bg-orange-50"
                >
                  <Play size={16} />
                  See the flow
                </a>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 18 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.55, delay: 0.26 }}
                className="mt-10 grid gap-4 md:grid-cols-3"
              >
                <Metric label="Starter credits" value="15" />
                <Metric label="Cost per scan" value="10" />
                <Metric label="Built for" value="Phone + desktop" />
              </motion.div>
            </div>

            <motion.div
              initial={{ opacity: 0, y: 28 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.15 }}
              className="relative"
            >
              <div className="rounded-[2rem] border border-stone-200 bg-[#fffaf4] p-4 shadow-[0_24px_60px_rgba(120,95,68,0.08)]">
                <div className="rounded-[1.7rem] border border-orange-100 bg-white p-5">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">
                        Live analysis
                      </div>
                      <div className="mt-2 text-xl font-black text-stone-900">
                        Visual trading summary
                      </div>
                    </div>
                    <div className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700">
                      Ready
                    </div>
                  </div>

                  <div className="mt-5 rounded-[1.6rem] bg-gradient-to-br from-stone-900 to-[#34261a] p-5 text-white">
                    <div className="mb-5 flex items-center justify-between">
                      <div className="text-sm font-semibold text-white/70">
                        Full-screen result preview
                      </div>
                      <ChartNoAxesCombined size={18} className="text-orange-300" />
                    </div>
                    <div className="grid gap-3 sm:grid-cols-3">
                      <Tile label="Bias" value="Bullish" tone="green" />
                      <Tile label="Risk" value="Medium" tone="amber" />
                      <Tile label="Confidence" value="82%" tone="orange" />
                    </div>
                    <div className="mt-5 grid gap-3">
                      <PreviewBlock title="When to BUY" body="Wait for a reclaim above the recent breakout shelf with stable volume." />
                      <PreviewBlock title="When to SELL" body="Scale out near resistance or exit fast on failed continuation." />
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </section>

        <section id="overview" className="mt-8 grid gap-5 md:grid-cols-3">
          <FeatureCard
            icon={<ShieldCheck size={18} />}
            title="Clean login flow"
            body="Start Now now opens a dedicated auth page, so the hero stays focused and uncluttered."
          />
          <FeatureCard
            icon={<Sparkles size={18} />}
            title="Visual-first output"
            body="Analysis opens large and immersive, with the uploaded chart and decision blocks front and center."
          />
          <FeatureCard
            icon={<ChartNoAxesCombined size={18} />}
            title="Mobile-friendly layout"
            body="Large tap targets, stacked blocks, and clearer spacing keep the app readable on phones."
          />
        </section>
      </div>
    </main>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[1.5rem] border border-stone-200 bg-[#fffaf4] p-4">
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{label}</div>
      <div className="mt-2 text-2xl font-black text-stone-900">{value}</div>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  body,
}: {
  icon: React.ReactNode;
  title: string;
  body: string;
}) {
  return (
    <div className="rounded-[1.8rem] border border-stone-200 bg-white/88 p-5 shadow-[0_16px_48px_rgba(120,95,68,0.08)]">
      <div className="mb-3 text-orange-500">{icon}</div>
      <h3 className="font-bold text-stone-900">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-stone-600">{body}</p>
    </div>
  );
}

function Tile({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone: 'green' | 'amber' | 'orange';
}) {
  const classes =
    tone === 'green'
      ? 'bg-emerald-500/16 text-emerald-200 border-emerald-400/20'
      : tone === 'amber'
        ? 'bg-amber-500/16 text-amber-200 border-amber-400/20'
        : 'bg-orange-500/16 text-orange-200 border-orange-400/20';

  return (
    <div className={['rounded-[1.3rem] border p-4', classes].join(' ')}>
      <div className="text-xs font-semibold uppercase tracking-[0.16em] opacity-70">{label}</div>
      <div className="mt-2 text-2xl font-black">{value}</div>
    </div>
  );
}

function PreviewBlock({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-[1.25rem] border border-white/10 bg-white/5 p-4">
      <div className="text-sm font-semibold text-white">{title}</div>
      <div className="mt-2 text-sm leading-6 text-white/70">{body}</div>
    </div>
  );
}
