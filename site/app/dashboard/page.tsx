import { Suspense } from 'react';

import { DashboardShell } from '@/components/dashboard-shell';

export default function DashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-[#0b0b0c] text-white">
          Loading dashboard...
        </div>
      }
    >
      <DashboardShell />
    </Suspense>
  );
}
