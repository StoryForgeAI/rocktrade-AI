import type { Metadata } from 'next';
import Script from 'next/script';
import type { ReactNode } from 'react';

import { themeScript } from '@/lib/theme-script';

import './globals.css';

export const metadata: Metadata = {
  title: 'SnapPrice Trading AI',
  description:
    'AI-powered screenshot analysis for crypto, stocks, forex, and trading dashboards.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="en" data-theme="dark">
      <body>
        <Script
          id="snapprice-theme"
          strategy="beforeInteractive"
          dangerouslySetInnerHTML={{ __html: themeScript }}
        />
        {children}
      </body>
    </html>
  );
}
