'use client';

import { MoonStar, SunMedium } from 'lucide-react';
import { useEffect, useState } from 'react';

import type { ThemeMode } from '@/lib/types';

export function ThemeToggle() {
  const [theme, setTheme] = useState<ThemeMode>('light');

  useEffect(() => {
    const current =
      document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light';
    setTheme(current);
  }, []);

  function toggleTheme() {
    const nextTheme = theme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = nextTheme;
    localStorage.setItem('tradescope-theme', nextTheme);
    setTheme(nextTheme);
  }

  return (
    <button
      type="button"
      onClick={toggleTheme}
      className={`inline-flex h-11 w-11 items-center justify-center rounded-2xl border transition ${
        theme === 'dark'
          ? 'border-white/10 bg-white/5 text-white hover:border-orange-400/50 hover:text-orange-200'
          : 'border-stone-200 bg-white text-stone-900 hover:border-orange-300 hover:text-orange-600'
      }`}
      aria-label="Toggle theme"
    >
      {theme === 'dark' ? <SunMedium size={18} /> : <MoonStar size={18} />}
    </button>
  );
}
