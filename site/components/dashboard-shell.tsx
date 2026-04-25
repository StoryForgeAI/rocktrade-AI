'use client';

import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowRight,
  CandlestickChart,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  Gauge,
  Info,
  LayoutDashboard,
  LoaderCircle,
  LogOut,
  Menu,
  RefreshCcw,
  Sparkles,
  UploadCloud,
  UserRound,
  X,
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

type ActiveTab = 'dashboard' | 'analyze' | 'plans' | 'profile' | 'about';

const tabs: { id: ActiveTab; label: string; icon: ReactNode }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: <LayoutDashboard size={17} /> },
  { id: 'analyze', label: 'Analyze', icon: <Sparkles size={17} /> },
  { id: 'plans', label: 'Plans', icon: <CreditCard size={17} /> },
  { id: 'profile', label: 'Profile', icon: <UserRound size={17} /> },
  { id: 'about', label: 'About', icon: <Info size={17} /> },
];

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
  const [activeTab, setActiveTab] = useState<ActiveTab>('dashboard');
  const [showResult, setShowResult] = useState(false);
  const [analysisStep, setAnalysisStep] = useState(0);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    void loadDashboard();
  }, []);

  useEffect(() => {
    const checkout = searchParams.get('checkout');
    if (checkout === 'success') {
      setMessage('Checkout completed. Your plan or credit balance may update in a few seconds.');
      setActiveTab('plans');
    }
    if (checkout === 'canceled') {
      setMessage('Checkout was canceled. No payment was taken.');
      setActiveTab('plans');
    }
  }, [searchParams]);

  useEffect(() => {
    return () => {
      if (upload.previewUrl) URL.revokeObjectURL(upload.previewUrl);
    };
  }, [upload.previewUrl]);

  useEffect(() => {
    if (!busy) {
      setAnalysisStep(0);
      return;
    }

    const timers = [
      window.setTimeout(() => setAnalysisStep(1), 650),
      window.setTimeout(() => setAnalysisStep(2), 1700),
      window.setTimeout(() => setAnalysisStep(3), 3000),
    ];

    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [busy]);

  const latestSaved = dashboard?.analyses[0] ?? null;
  const effectiveAnalysis = analysis ?? latestSaved?.result ?? null;
  const hasFile = Boolean(upload.file) || Boolean(upload.previewUrl);

  const canAnalyze = useMemo(() => {
    return hasFile && !busy;
  }, [hasFile, busy]);

  async function loadDashboard() {
    setLoading(true);
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session) {
        router.replace('/auth');
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
        analyses: (analyses as AnalysisRecord[]) ?? [],
      });
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not load your dashboard.');
    } finally {
      setLoading(false);
    }
  }

  function onFileChange(file: File | null) {
    if (upload.previewUrl) URL.revokeObjectURL(upload.previewUrl);
    if (!file) {
      setUpload({ file: null, previewUrl: null });
      return;
    }

    setUpload({
      file,
      previewUrl: URL.createObjectURL(file),
    });
    setMessage(`Selected file: ${file.name}`);
  }

  async function handleAnalyze() {
    if (!upload.file || !dashboard) {
      setMessage('Please select a chart screenshot first.');
      return;
    }

    if (dashboard.profile.credits < ANALYSIS_COST) {
      setMessage('Not enough credits. Please add credits or switch plans.');
      setActiveTab('plans');
      return;
    }

    setBusy(true);
    setMessage(null);
    setActiveTab('analyze');

    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        router.replace('/auth');
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
      if (!data?.analysis) throw new Error('No analysis came back from the server.');

      setAnalysis(data.analysis as TradeAnalysis);
      setShowResult(true);
      setMessage('Analysis complete. The chart was saved and your credits were updated.');
      await loadDashboard();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Analysis failed.');
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
      if (!data?.url) throw new Error('Missing Stripe checkout URL.');
      window.location.href = data.url as string;
    } catch (error) {
      setBusy(false);
      setMessage(error instanceof Error ? error.message : 'Could not open checkout.');
    }
  }

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.replace('/auth');
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center text-stone-700">
        <LoaderCircle className="animate-spin text-orange-500" size={28} />
      </div>
    );
  }

  if (!dashboard) return null;

  return (
    <main className="min-h-screen px-3 py-3 md:px-6 md:py-6">
      <div className="mx-auto flex max-w-7xl gap-4">
        <Sidebar
          activeTab={activeTab}
          setActiveTab={(tab) => {
            setActiveTab(tab);
            setMobileMenuOpen(false);
          }}
          profile={dashboard.profile}
          collapsed={sidebarCollapsed}
          setCollapsed={setSidebarCollapsed}
          mobileOpen={mobileMenuOpen}
          setMobileOpen={setMobileMenuOpen}
          onSignOut={() => void handleSignOut()}
        />

        <div className="min-w-0 flex-1">
          <TopBar
            busy={busy}
            onRefresh={() => void loadDashboard()}
            onToggleSidebar={() => setMobileMenuOpen(true)}
          />

          {message ? (
            <div className="mb-4 flex items-start gap-3 rounded-[1.5rem] border border-emerald-200 bg-emerald-50 px-5 py-4 text-sm text-emerald-900">
              <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-emerald-600" />
              <span>{message}</span>
            </div>
          ) : null}

          <AnimatePresence mode="wait">
            <motion.section
              key={activeTab}
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -18 }}
              transition={{ duration: 0.22 }}
            >
              {activeTab === 'dashboard' && (
                <DashboardTab
                  dashboard={dashboard}
                  analysis={effectiveAnalysis}
                  onOpenAnalyze={() => setActiveTab('analyze')}
                  onOpenPlans={() => setActiveTab('plans')}
                />
              )}

              {activeTab === 'analyze' && (
                <AnalyzeTab
                  dashboard={dashboard}
                  upload={upload}
                  dragging={dragging}
                  busy={busy}
                  canAnalyze={canAnalyze}
                  analysisStep={analysisStep}
                  onFileChange={onFileChange}
                  onAnalyze={() => void handleAnalyze()}
                  setDragging={setDragging}
                />
              )}

              {activeTab === 'plans' && (
                <PlansTab
                  currentPlan={dashboard.profile.plan}
                  onCheckout={(id, mode) => void handleCheckout(id, mode)}
                />
              )}

              {activeTab === 'profile' && (
                <ProfileTab
                  dashboard={dashboard}
                  onCheckout={() => setActiveTab('plans')}
                  onAnalyze={() => setActiveTab('analyze')}
                />
              )}

              {activeTab === 'about' && <AboutTab />}
            </motion.section>
          </AnimatePresence>
        </div>
      </div>

      <AnimatePresence>
        {showResult && effectiveAnalysis ? (
          <ResultOverlay
            analysis={effectiveAnalysis}
            previewUrl={upload.previewUrl}
            savedAt={latestSaved?.created_at ?? null}
            onClose={() => setShowResult(false)}
          />
        ) : null}
      </AnimatePresence>
    </main>
  );
}

function Sidebar({
  activeTab,
  setActiveTab,
  profile,
  collapsed,
  setCollapsed,
  mobileOpen,
  setMobileOpen,
  onSignOut,
}: {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  profile: UserProfile;
  collapsed: boolean;
  setCollapsed: (value: boolean) => void;
  mobileOpen: boolean;
  setMobileOpen: (value: boolean) => void;
  onSignOut: () => void;
}) {
  return (
    <>
      <AnimatePresence>
        {mobileOpen ? (
          <motion.button
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            type="button"
            onClick={() => setMobileOpen(false)}
            className="fixed inset-0 z-40 bg-black/25 md:hidden"
            aria-label="Close menu overlay"
          />
        ) : null}
      </AnimatePresence>

      <motion.aside
        initial={false}
        animate={{
          width: collapsed ? 94 : 280,
          x: mobileOpen ? 0 : undefined,
        }}
        className={cn(
          'fixed inset-y-3 left-3 z-50 rounded-[2rem] border border-orange-100 bg-white/92 p-3 shadow-[0_24px_80px_rgba(177,123,52,0.12)] backdrop-blur md:sticky md:top-6 md:z-10 md:h-[calc(100vh-3rem)]',
          mobileOpen ? 'translate-x-0' : '-translate-x-[110%] md:translate-x-0',
        )}
      >
        <div className="flex h-full flex-col">
          <div className="mb-5 flex items-center justify-between gap-2 px-2">
            <div className="flex items-center gap-3 overflow-hidden">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-orange-500 to-amber-300 text-white shadow-glow">
                <CandlestickChart size={20} />
              </div>
              {!collapsed ? (
                <div>
                  <div className="text-sm font-semibold uppercase tracking-[0.22em] text-orange-500">
                    TradeScope
                  </div>
                  <div className="text-xs text-stone-500">{profile.email}</div>
                </div>
              ) : null}
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCollapsed(!collapsed)}
                className="hidden h-10 w-10 items-center justify-center rounded-2xl border border-stone-200 bg-white text-stone-700 md:inline-flex"
                aria-label="Collapse menu"
              >
                {collapsed ? <ChevronRight size={17} /> : <ChevronLeft size={17} />}
              </button>
              <button
                type="button"
                onClick={() => setMobileOpen(false)}
                className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-stone-200 bg-white text-stone-700 md:hidden"
                aria-label="Close mobile menu"
              >
                <X size={17} />
              </button>
            </div>
          </div>

          <div className="space-y-2">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                className={cn(
                  'flex w-full items-center gap-3 rounded-2xl px-3 py-3 text-left text-sm font-semibold transition',
                  activeTab === tab.id
                    ? 'bg-orange-500 text-white shadow-[0_12px_30px_rgba(249,115,22,0.24)]'
                    : 'text-stone-600 hover:bg-orange-50 hover:text-stone-900',
                  collapsed && 'justify-center',
                )}
              >
                {tab.icon}
                {!collapsed ? <span>{tab.label}</span> : null}
              </button>
            ))}
          </div>

          <div className="mt-auto space-y-3 px-2">
            {!collapsed ? (
              <div className="rounded-[1.5rem] border border-stone-200 bg-stone-50 p-4">
                <div className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full bg-emerald-500" />
                  <span className="text-sm font-semibold text-stone-900">Ready</span>
                </div>
              </div>
            ) : (
              <div className="flex justify-center py-2">
                <span className="h-3 w-3 rounded-full bg-emerald-500" />
              </div>
            )}

            <button
              type="button"
              onClick={onSignOut}
              className={cn(
                'flex w-full items-center gap-3 rounded-2xl border border-stone-200 bg-white px-3 py-3 text-sm font-semibold text-stone-700 transition hover:border-stone-300',
                collapsed && 'justify-center',
              )}
            >
              <LogOut size={17} />
              {!collapsed ? 'Sign out' : null}
            </button>
          </div>
        </div>
      </motion.aside>
    </>
  );
}

function TopBar({
  busy,
  onRefresh,
  onToggleSidebar,
}: {
  busy: boolean;
  onRefresh: () => void;
  onToggleSidebar: () => void;
}) {
  return (
    <div className="mb-4 flex items-center justify-between gap-3 rounded-[1.75rem] border border-orange-100 bg-white/92 px-4 py-3 shadow-[0_20px_60px_rgba(177,123,52,0.10)] backdrop-blur">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onToggleSidebar}
          className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-stone-200 bg-white text-stone-700 md:hidden"
          aria-label="Open menu"
        >
          <Menu size={18} />
        </button>
        <div className="flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-semibold text-emerald-700">
          <span className={cn('h-2.5 w-2.5 rounded-full bg-emerald-500', busy && 'animate-pulse')} />
          {busy ? 'Running' : 'Ready'}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <ThemeToggle />
        <button
          type="button"
          onClick={onRefresh}
          className="inline-flex h-11 items-center gap-2 rounded-2xl border border-orange-200 bg-orange-50 px-4 text-sm font-semibold text-stone-800 transition hover:border-orange-300 hover:bg-orange-100"
        >
          <RefreshCcw size={16} />
          Refresh
        </button>
      </div>
    </div>
  );
}

function DashboardTab({
  dashboard,
  analysis,
  onOpenAnalyze,
  onOpenPlans,
}: {
  dashboard: DashboardData;
  analysis: TradeAnalysis | null;
  onOpenAnalyze: () => void;
  onOpenPlans: () => void;
}) {
  return (
    <div className="grid gap-6 xl:grid-cols-[1.12fr_0.88fr]">
      <Card className="overflow-hidden bg-gradient-to-br from-[#fff9f2] via-white to-[#fff3df]">
        <div className="grid gap-8 lg:grid-cols-[1.12fr_0.88fr]">
          <div>
            <SectionEyebrow>Overview</SectionEyebrow>
            <h2 className="mt-3 text-3xl font-black text-stone-900">
              Your trading workspace is ready.
            </h2>
            <p className="mt-4 max-w-xl text-sm leading-7 text-stone-600">
              Move fast between uploads, plans, profile, and your recent analysis history through the sidebar.
            </p>
            <div className="mt-6 grid gap-4 sm:grid-cols-3">
              <MetricCard label="Credits" value={String(dashboard.profile.credits)} />
              <MetricCard label="Plan" value={dashboard.profile.plan} />
              <MetricCard label="Saved" value={String(dashboard.analyses.length)} />
            </div>
            <div className="mt-6 flex flex-wrap gap-3">
              <PrimaryButton onClick={onOpenAnalyze}>Analyze now</PrimaryButton>
              <SecondaryButton onClick={onOpenPlans}>Open plans</SecondaryButton>
            </div>
          </div>

          <div className="rounded-[2rem] border border-orange-100 bg-white/90 p-5">
            <div className="mb-5 text-sm font-semibold text-stone-500">Quick snapshot</div>
            {analysis ? (
              <div className="space-y-3">
                <SummaryRow label="Bias" value={analysis.marketSentiment} />
                <SummaryRow label="Risk" value={analysis.riskLevel} />
                <SummaryRow label="Confidence" value={`${analysis.confidenceScore}%`} />
                <SummaryRow label="Buy focus" value={analysis.whenToBuy} multiline />
              </div>
            ) : (
              <EmptyState text="Run your first analysis to see the latest AI summary here." />
            )}
          </div>
        </div>
      </Card>

      <Card>
        <SectionEyebrow>Recent activity</SectionEyebrow>
        <h3 className="mt-3 text-xl font-black text-stone-900">Saved analyses</h3>
        <div className="mt-5 space-y-3">
          {dashboard.analyses.length ? (
            dashboard.analyses.slice(0, 5).map((item) => (
              <div
                key={item.id}
                className="rounded-[1.5rem] border border-stone-200 bg-stone-50 px-4 py-4"
              >
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="font-semibold capitalize text-stone-900">
                      {item.result.marketSentiment} market bias
                    </div>
                    <div className="mt-1 text-sm leading-6 text-stone-600">
                      {item.result.entrySuggestion}
                    </div>
                  </div>
                  <div className="text-right text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">
                    {item.result.confidenceScore}%
                  </div>
                </div>
                <div className="mt-3 text-xs text-stone-500">{formatDate(item.created_at)}</div>
              </div>
            ))
          ) : (
            <EmptyState text="Your saved analyses will appear here after the first completed upload." />
          )}
        </div>
      </Card>
    </div>
  );
}

function AnalyzeTab({
  dashboard,
  upload,
  dragging,
  busy,
  canAnalyze,
  analysisStep,
  onFileChange,
  onAnalyze,
  setDragging,
}: {
  dashboard: DashboardData;
  upload: UploadState;
  dragging: boolean;
  busy: boolean;
  canAnalyze: boolean;
  analysisStep: number;
  onFileChange: (file: File | null) => void;
  onAnalyze: () => void;
  setDragging: (value: boolean) => void;
}) {
  const progress = [18, 46, 78, 100][analysisStep] ?? 0;
  const hasCredits = dashboard.profile.credits >= ANALYSIS_COST;

  return (
    <div className="grid gap-6 xl:grid-cols-[1.08fr_0.92fr]">
      <Card>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <SectionEyebrow>Analyze</SectionEyebrow>
            <h2 className="mt-3 text-2xl font-black text-stone-900">
              Upload a chart and launch the AI reading flow
            </h2>
          </div>
          <div className="rounded-full border border-orange-200 bg-orange-50 px-4 py-2 text-sm font-semibold text-stone-700">
            {ANALYSIS_COST} credits per analysis
          </div>
        </div>

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
            if (dropped) onFileChange(dropped);
          }}
          className={cn(
            'mt-6 rounded-[2rem] border border-dashed p-5 transition',
            dragging ? 'border-orange-400 bg-orange-50' : 'border-stone-300 bg-stone-50/80',
          )}
        >
          {upload.previewUrl ? (
            <img
              src={upload.previewUrl}
              alt="Selected chart"
              className="h-[340px] w-full rounded-[1.5rem] object-cover"
            />
          ) : (
            <div className="flex h-[340px] flex-col items-center justify-center rounded-[1.5rem] border border-stone-200 bg-white text-center">
              <UploadCloud size={28} className="mb-4 text-orange-500" />
              <div className="text-lg font-semibold text-stone-900">Drop a trading screenshot here</div>
              <div className="mt-2 max-w-md text-sm leading-6 text-stone-600">
                Works great with TradingView, Binance, MetaTrader, broker dashboards, crypto, forex, and stocks.
              </div>
            </div>
          )}

          <div className="mt-5 flex flex-wrap gap-3">
            <label className="inline-flex cursor-pointer items-center gap-2 rounded-2xl bg-stone-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-stone-800">
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(event) => onFileChange(event.target.files?.[0] ?? null)}
              />
              Choose screenshot
            </label>

            <PrimaryButton onClick={onAnalyze} disabled={!canAnalyze || !hasCredits}>
              {busy ? <LoaderCircle className="animate-spin" size={16} /> : <Sparkles size={16} />}
              Run AI analysis
            </PrimaryButton>
          </div>

          <div className="mt-4 flex flex-wrap items-center gap-3 text-sm">
            <span className="rounded-full border border-stone-200 bg-white px-3 py-2 text-stone-700">
              {upload.file ? `Selected: ${upload.file.name}` : 'No screenshot selected yet'}
            </span>
            <span
              className={cn(
                'rounded-full px-3 py-2',
                hasCredits
                  ? 'border border-emerald-200 bg-emerald-50 text-emerald-700'
                  : 'border border-rose-200 bg-rose-50 text-rose-700',
              )}
            >
              {hasCredits
                ? `${dashboard.profile.credits} credits available`
                : 'Not enough credits to run analysis'}
            </span>
          </div>
        </div>
      </Card>

      <Card className="overflow-hidden bg-gradient-to-br from-white via-[#fff9f1] to-[#fff2e1]">
        <SectionEyebrow>Process</SectionEyebrow>
        <h3 className="mt-3 text-2xl font-black text-stone-900">Animated analysis flow</h3>
        <p className="mt-3 text-sm leading-7 text-stone-600">
          The process is visual and simple: upload, structure reading, confidence scoring, and a full-screen result.
        </p>

        <div className="mt-6 rounded-[1.75rem] border border-orange-100 bg-white/85 p-5">
          <div className="flex items-center justify-between text-sm font-semibold text-stone-700">
            <span>AI progress</span>
            <span>{busy ? `${progress}%` : 'Waiting for your screenshot'}</span>
          </div>
          <div className="mt-3 h-3 rounded-full bg-orange-100">
            <motion.div
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.4 }}
              className="h-3 rounded-full bg-gradient-to-r from-orange-500 to-amber-300"
            />
          </div>
          <div className="mt-5 space-y-3">
            <ProcessStep active={busy && analysisStep >= 0} label="Uploading the chart screenshot" />
            <ProcessStep active={busy && analysisStep >= 1} label="Reading structure, trend, and momentum" />
            <ProcessStep active={busy && analysisStep >= 2} label="Scoring confidence and risk" />
            <ProcessStep active={busy && analysisStep >= 3} label="Opening the full-screen analysis view" />
          </div>
        </div>
      </Card>
    </div>
  );
}

function PlansTab({
  currentPlan,
  onCheckout,
}: {
  currentPlan: string;
  onCheckout: (id: string, mode: 'payment' | 'subscription') => void;
}) {
  return (
    <div className="space-y-6">
      <Card className="bg-gradient-to-br from-[#fff9f2] to-white">
        <SectionEyebrow>Plans</SectionEyebrow>
        <h2 className="mt-3 text-3xl font-black text-stone-900">Subscriptions and credit packs</h2>
        <p className="mt-3 max-w-2xl text-sm leading-7 text-stone-600">
          Use subscriptions for steady weekly credits, or top up with one-time packs whenever you need more analysis volume.
        </p>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        {SUBSCRIPTIONS.map((plan) => (
          <PlanCard
            key={plan.id}
            title={plan.title}
            price={plan.priceLabel}
            description={plan.description}
            featured={currentPlan === plan.id}
            buttonLabel={currentPlan === plan.id ? 'Current plan' : 'Open checkout'}
            onClick={() => onCheckout(plan.id, plan.mode)}
          />
        ))}
      </div>

      <Card>
        <div className="mb-5">
          <SectionEyebrow>Credit packs</SectionEyebrow>
          <h3 className="mt-3 text-2xl font-black text-stone-900">One-time packs</h3>
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          {CREDIT_PACKS.map((pack) => (
            <PlanCard
              key={pack.id}
              title={pack.title}
              price={pack.priceLabel}
              description={pack.description}
              buttonLabel="Buy credits"
              compact
              onClick={() => onCheckout(pack.id, pack.mode)}
            />
          ))}
        </div>
      </Card>
    </div>
  );
}

function ProfileTab({
  dashboard,
  onCheckout,
  onAnalyze,
}: {
  dashboard: DashboardData;
  onCheckout: () => void;
  onAnalyze: () => void;
}) {
  return (
    <div className="grid gap-6 xl:grid-cols-[0.92fr_1.08fr]">
      <Card>
        <SectionEyebrow>Profile</SectionEyebrow>
        <h2 className="mt-3 text-2xl font-black text-stone-900">Account details</h2>
        <div className="mt-6 space-y-3">
          <InfoLine label="Email" value={dashboard.profile.email} />
          <InfoLine label="Credits" value={String(dashboard.profile.credits)} />
          <InfoLine label="Plan" value={dashboard.profile.plan} />
          <InfoLine label="Member since" value={formatDate(dashboard.profile.created_at)} />
          <InfoLine
            label="Current period end"
            value={formatDate(dashboard.subscription?.current_period_end)}
          />
        </div>
        <div className="mt-6 flex flex-wrap gap-3">
          <PrimaryButton onClick={onAnalyze}>Analyze a chart</PrimaryButton>
          <SecondaryButton onClick={onCheckout}>See plans</SecondaryButton>
        </div>
      </Card>

      <Card>
        <SectionEyebrow>Performance</SectionEyebrow>
        <h3 className="mt-3 text-2xl font-black text-stone-900">Clear account visuals</h3>
        <p className="mt-3 text-sm leading-7 text-stone-600">
          A lighter dashboard with just enough visual structure to stay readable on phones and laptops.
        </p>
        <div className="mt-6 grid gap-4 md:grid-cols-3">
          <StatTile title="Credits left" value={String(dashboard.profile.credits)} accent="orange" />
          <StatTile title="Saved analyses" value={String(dashboard.analyses.length)} accent="blue" />
          <StatTile title="Account tier" value={dashboard.profile.plan} accent="green" />
        </div>
        <div className="mt-6 rounded-[1.75rem] border border-stone-200 bg-stone-50 p-5">
          <div className="mb-4 text-sm font-semibold text-stone-700">Visual balance</div>
          <BarsChart
            items={[
              { label: 'Signal confidence', value: Math.min(92, 35 + dashboard.analyses.length * 7) },
              { label: 'Recent activity', value: Math.min(100, dashboard.analyses.length * 12) },
              { label: 'Credit runway', value: Math.min(100, dashboard.profile.credits) },
            ]}
          />
        </div>
      </Card>
    </div>
  );
}

function AboutTab() {
  return (
    <div className="grid gap-6 xl:grid-cols-[1fr_1fr]">
      <Card className="bg-gradient-to-br from-[#fff7ec] to-white">
        <SectionEyebrow>About</SectionEyebrow>
        <h2 className="mt-3 text-3xl font-black text-stone-900">What TradeScope focuses on</h2>
        <div className="mt-6 space-y-4 text-sm leading-7 text-stone-600">
          <AboutRow
            icon={<Sparkles size={16} />}
            title="Fast chart reading"
            body="Upload screenshots from crypto, forex, or stock platforms and get structured insight in a cleaner format."
          />
          <AboutRow
            icon={<Gauge size={16} />}
            title="Visual-first result"
            body="The analysis opens in a full-screen readout built to feel clear instead of text-heavy."
          />
          <AboutRow
            icon={<Info size={16} />}
            title="Simple navigation"
            body="A collapsible sidebar keeps Dashboard, Analyze, Plans, Profile, and About one tap away."
          />
        </div>
      </Card>

      <Card>
        <SectionEyebrow>Design direction</SectionEyebrow>
        <h3 className="mt-3 text-2xl font-black text-stone-900">Lighter, cleaner, easier to scan</h3>
        <p className="mt-3 text-sm leading-7 text-stone-600">
          The product now leans into a brighter editorial SaaS look, with a sharper landing page, a dedicated auth route, and an app layout that feels more like a polished workspace.
        </p>
        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <MiniMetric title="Primary style" value="Light, warm, premium" />
          <MiniMetric title="Optimized for" value="Phone and desktop" />
          <MiniMetric title="Result format" value="Full-screen report" />
          <MiniMetric title="Language" value="English only" />
        </div>
      </Card>
    </div>
  );
}

function ResultOverlay({
  analysis,
  previewUrl,
  savedAt,
  onClose,
}: {
  analysis: TradeAnalysis;
  previewUrl: string | null;
  savedAt: string | null;
  onClose: () => void;
}) {
  const confidence = Math.max(0, Math.min(100, analysis.confidenceScore));
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 overflow-y-auto bg-[rgba(252,247,240,0.92)] backdrop-blur-md"
    >
      <div className="mx-auto min-h-screen max-w-7xl px-4 py-4 md:px-8 md:py-8">
        <div className="rounded-[2rem] border border-orange-100 bg-white shadow-[0_32px_120px_rgba(180,118,42,0.18)]">
          <div className="sticky top-0 z-10 flex items-center justify-between rounded-t-[2rem] border-b border-stone-200 bg-white/92 px-5 py-4 backdrop-blur md:px-8">
            <div>
              <div className="text-xs font-semibold uppercase tracking-[0.24em] text-orange-500">
                Analysis result
              </div>
              <div className="mt-1 text-lg font-bold text-stone-900">Full-screen trade readout</div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-stone-200 bg-white text-stone-700 transition hover:border-stone-300"
              aria-label="Close analysis"
            >
              <X size={18} />
            </button>
          </div>

          <div className="grid gap-8 px-5 py-5 md:px-8 md:py-8 xl:grid-cols-[1fr_1.04fr]">
            <div className="space-y-6">
              <div className="overflow-hidden rounded-[1.8rem] border border-stone-200 bg-stone-50">
                {previewUrl ? (
                  <img
                    src={previewUrl}
                    alt="Uploaded chart"
                    className="h-[320px] w-full object-cover md:h-[460px]"
                  />
                ) : (
                  <div className="flex h-[320px] items-center justify-center text-stone-400 md:h-[460px]">
                    Uploaded chart preview
                  </div>
                )}
              </div>

              <div className="grid gap-3 sm:grid-cols-3">
                <SignalCard title="Bias" value={analysis.marketSentiment} tone={analysis.marketSentiment} />
                <SignalCard title="Risk" value={analysis.riskLevel} tone={analysis.riskLevel} />
                <SignalCard title="Confidence" value={`${confidence}%`} tone="confidence" />
              </div>

              <Card className="p-5">
                <div className="mb-4 text-sm font-semibold text-stone-700">Scoreboard</div>
                <BarsChart
                  items={[
                    { label: 'Confidence', value: confidence },
                    {
                      label: 'Momentum',
                      value: confidence > 50 ? Math.min(98, confidence + 4) : confidence + 16,
                    },
                    {
                      label: 'Risk control',
                      value: analysis.riskLevel === 'low' ? 84 : analysis.riskLevel === 'medium' ? 62 : 38,
                    },
                  ]}
                />
                <div className="mt-4 text-xs text-stone-500">
                  {savedAt ? `Saved ${formatDate(savedAt)}` : 'Fresh analysis'}
                </div>
              </Card>
            </div>

            <div className="space-y-6">
              <Card className="p-6">
                <SectionEyebrow>Trade summary</SectionEyebrow>
                <h2 className="mt-3 text-3xl font-black text-stone-900">
                  Clear buy and sell guidance with less noise
                </h2>
                <div className="mt-6 grid gap-4 md:grid-cols-2">
                  <InsightPanel title="What is happening?" body={analysis.whatIsHappening} />
                  <InsightPanel title="Why" body={analysis.reasoning} />
                  <InsightPanel title="When to BUY" body={analysis.whenToBuy} emphasis />
                  <InsightPanel title="When to SELL" body={analysis.whenToSell} emphasis />
                </div>
              </Card>

              <Card className="p-6">
                <div className="mb-4 text-sm font-semibold text-stone-700">Entry and exit map</div>
                <TradeLane analysis={analysis} />
              </Card>

              <Card className="p-6">
                <div className="mb-4 text-sm font-semibold text-stone-700">Signals detected</div>
                <div className="flex flex-wrap gap-2">
                  {[...analysis.keySignals, ...analysis.detectedIndicators].map((item) => (
                    <span
                      key={item}
                      className="rounded-full border border-orange-200 bg-orange-50 px-3 py-2 text-xs font-semibold text-stone-700"
                    >
                      {item}
                    </span>
                  ))}
                </div>
              </Card>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function TradeLane({ analysis }: { analysis: TradeAnalysis }) {
  return (
    <div className="relative overflow-hidden rounded-[1.5rem] border border-stone-200 bg-[#fffaf5] p-5">
      <div className="absolute left-6 right-6 top-1/2 h-[2px] -translate-y-1/2 bg-gradient-to-r from-stone-200 via-orange-300 to-stone-200" />
      <div className="relative grid gap-4 md:grid-cols-3">
        <LaneNode title="Market state" body={analysis.marketSentiment} />
        <LaneNode title="Buy trigger" body={analysis.whenToBuy} highlighted />
        <LaneNode title="Sell trigger" body={analysis.whenToSell} />
      </div>
    </div>
  );
}

function LaneNode({
  title,
  body,
  highlighted = false,
}: {
  title: string;
  body: string;
  highlighted?: boolean;
}) {
  return (
    <div
      className={cn(
        'relative rounded-[1.4rem] border p-4 shadow-sm',
        highlighted ? 'border-orange-300 bg-white' : 'border-stone-200 bg-white/80',
      )}
    >
      <div className="mb-3 h-3 w-3 rounded-full bg-orange-400" />
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{title}</div>
      <div className="mt-3 text-sm leading-6 text-stone-700">{body}</div>
    </div>
  );
}

function InsightPanel({
  title,
  body,
  emphasis = false,
}: {
  title: string;
  body: string;
  emphasis?: boolean;
}) {
  return (
    <div
      className={cn(
        'rounded-[1.5rem] border p-5',
        emphasis ? 'border-orange-200 bg-orange-50' : 'border-stone-200 bg-stone-50',
      )}
    >
      <div className="text-sm font-semibold text-stone-900">{title}</div>
      <p className="mt-3 text-sm leading-7 text-stone-600">{body}</p>
    </div>
  );
}

function BarsChart({ items }: { items: { label: string; value: number }[] }) {
  return (
    <div className="space-y-4">
      {items.map((item) => (
        <div key={item.label}>
          <div className="mb-2 flex items-center justify-between text-sm">
            <span className="font-medium text-stone-700">{item.label}</span>
            <span className="font-semibold text-stone-500">{item.value}%</span>
          </div>
          <div className="h-3 rounded-full bg-stone-200">
            <div
              className="h-3 rounded-full bg-gradient-to-r from-orange-500 to-amber-300"
              style={{ width: `${Math.max(8, Math.min(100, item.value))}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

function AboutRow({
  icon,
  title,
  body,
}: {
  icon: ReactNode;
  title: string;
  body: string;
}) {
  return (
    <div className="flex items-start gap-3 rounded-[1.5rem] border border-stone-200 bg-white p-4">
      <div className="rounded-2xl bg-orange-50 p-3 text-orange-500">{icon}</div>
      <div>
        <div className="font-semibold text-stone-900">{title}</div>
        <div className="mt-1 text-sm leading-6 text-stone-600">{body}</div>
      </div>
    </div>
  );
}

function ProcessStep({ active, label }: { active: boolean; label: string }) {
  return (
    <div className="flex items-center gap-3">
      <div
        className={cn(
          'h-3 w-3 rounded-full transition',
          active ? 'bg-orange-500 shadow-[0_0_0_6px_rgba(249,115,22,0.16)]' : 'bg-stone-300',
        )}
      />
      <div className={cn('text-sm', active ? 'text-stone-900' : 'text-stone-500')}>{label}</div>
    </div>
  );
}

function PlanCard({
  title,
  price,
  description,
  buttonLabel,
  onClick,
  featured = false,
  compact = false,
}: {
  title: string;
  price: string;
  description: string;
  buttonLabel: string;
  onClick: () => void;
  featured?: boolean;
  compact?: boolean;
}) {
  return (
    <div
      className={cn(
        'rounded-[1.75rem] border p-5',
        featured ? 'border-orange-300 bg-orange-50' : 'border-stone-200 bg-white',
      )}
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <div className="text-lg font-black text-stone-900">{title}</div>
          <div className="mt-2 text-base font-semibold text-stone-700">{price}</div>
          <div className="mt-2 text-sm leading-6 text-stone-600">{description}</div>
        </div>
        {featured ? (
          <span className="rounded-full border border-orange-300 bg-white px-3 py-1 text-xs font-semibold text-orange-600">
            Current
          </span>
        ) : null}
      </div>
      <button
        type="button"
        onClick={onClick}
        className={cn(
          'mt-5 inline-flex items-center gap-2 rounded-2xl px-4 py-3 text-sm font-semibold transition',
          compact
            ? 'border border-stone-200 bg-stone-900 text-white hover:bg-stone-800'
            : 'border border-orange-200 bg-stone-900 text-white hover:bg-stone-800',
        )}
      >
        {buttonLabel}
        <ArrowRight size={16} />
      </button>
    </div>
  );
}

function SignalCard({
  title,
  value,
  tone,
}: {
  title: string;
  value: string;
  tone: string;
}) {
  const palette =
    tone === 'bullish' || tone === 'low'
      ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
      : tone === 'bearish' || tone === 'high'
        ? 'border-rose-200 bg-rose-50 text-rose-700'
        : tone === 'confidence'
          ? 'border-orange-200 bg-orange-50 text-orange-700'
          : 'border-amber-200 bg-amber-50 text-amber-700';

  return (
    <div className={cn('rounded-[1.5rem] border p-4', palette)}>
      <div className="text-xs font-semibold uppercase tracking-[0.18em] opacity-70">{title}</div>
      <div className="mt-2 text-2xl font-black capitalize">{value}</div>
    </div>
  );
}

function Card({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <section
      className={cn(
        'rounded-[2rem] border border-stone-200 bg-white p-5 shadow-[0_18px_60px_rgba(120,95,68,0.08)] md:p-6',
        className,
      )}
    >
      {children}
    </section>
  );
}

function SectionEyebrow({ children }: { children: ReactNode }) {
  return <div className="text-xs font-semibold uppercase tracking-[0.22em] text-orange-500">{children}</div>;
}

function MiniMetric({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-[1.5rem] border border-stone-200 bg-white p-4">
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{title}</div>
      <div className="mt-2 text-xl font-black capitalize text-stone-900">{value}</div>
    </div>
  );
}

function MetricCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[1.5rem] border border-orange-100 bg-white/85 px-5 py-4">
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{label}</div>
      <div className="mt-2 text-2xl font-black capitalize text-stone-900">{value}</div>
    </div>
  );
}

function SummaryRow({
  label,
  value,
  multiline = false,
}: {
  label: string;
  value: string;
  multiline?: boolean;
}) {
  return (
    <div className="rounded-[1.2rem] bg-stone-50 px-4 py-3">
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{label}</div>
      <div className={cn('mt-2 text-sm font-semibold text-stone-800', multiline && 'leading-6')}>{value}</div>
    </div>
  );
}

function InfoLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-[1.2rem] bg-stone-50 px-4 py-3">
      <div className="text-sm text-stone-500">{label}</div>
      <div className="text-right text-sm font-semibold capitalize text-stone-800">{value}</div>
    </div>
  );
}

function EmptyState({ text }: { text: string }) {
  return (
    <div className="rounded-[1.5rem] border border-stone-200 bg-stone-50 p-5 text-sm leading-6 text-stone-600">
      {text}
    </div>
  );
}

function StatTile({
  title,
  value,
  accent,
}: {
  title: string;
  value: string;
  accent: 'orange' | 'blue' | 'green';
}) {
  const palette =
    accent === 'orange'
      ? 'bg-orange-50 border-orange-200'
      : accent === 'blue'
        ? 'bg-sky-50 border-sky-200'
        : 'bg-emerald-50 border-emerald-200';
  return (
    <div className={cn('rounded-[1.5rem] border p-5', palette)}>
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-stone-400">{title}</div>
      <div className="mt-2 text-2xl font-black capitalize text-stone-900">{value}</div>
    </div>
  );
}

function PrimaryButton({
  children,
  onClick,
  disabled,
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="inline-flex items-center gap-2 rounded-2xl bg-stone-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {children}
    </button>
  );
}

function SecondaryButton({
  children,
  onClick,
}: {
  children: ReactNode;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex items-center gap-2 rounded-2xl border border-stone-200 bg-white px-5 py-3 text-sm font-semibold text-stone-700 transition hover:border-stone-300"
    >
      {children}
    </button>
  );
}
