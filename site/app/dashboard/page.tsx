import { Suspense } from 'react';

import { DashboardShell } from '@/components/dashboard-shell';

export const dynamic = 'force-dynamic';

export default function DashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-[#fffaf4] text-stone-900">
          Loading TradeScope dashboard...
        </div>
      }
    >
      <div data-dashboard-version="v2-sidebar-layout">
        <DashboardShell />
      </div>
    </Suspense>
  );
}
